//
//  InputController.swift
//  Patal
//
//  Created by TemplarAssassin on 2022/03/13.
//

import Foundation
import InputMethodKit

@objc(PatIMKController)
class InputController: IMKInputController {
    internal let logger = CustomLogger(category: "InputController")

    // 클라이언트 하나 당 하나의 입력기 레이아웃 인스턴스가 사용됨
    internal var layoutName: LayoutName
    internal var optionMenu: OptionMenu

    var processor: HangulProcessor

    // 현재 컨트롤러가 활성 상태인지 추적
    private(set) var isControllerActivated: Bool = false
    // 동기화 중복 방지 플래그
    private(set) var isInstanceSynced: Bool = false

    // 클래스 생성이 하나의 인스턴스에서 이루어지기 때문에 여러개의 Patal 입력기를 동시에 사용할 수 없음.
    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        guard let inputMethodID = getCurrentInputMethodID() else {
            return nil
        }

        layoutName = getInputLayoutID(id: inputMethodID)
        logger.debug("팥알 입력기 자판: \(layoutName)")

        let traitKey = buildTraitKey(name: layoutName)
        let hangulLayout = createLayoutInstance(name: layoutName)
        processor = HangulProcessor(layout: hangulLayout)
        logger.debug("팥알 입력기 처리기: \(processor)")

        if let loadedTraits = loadActiveOptions(traitKey: traitKey) {
            processor.hangulLayout.traits = loadedTraits
        } else {
            processor.hangulLayout.traits = processor.hangulLayout.availableTraits.subtracting([.글자단위삭제])
        }

        optionMenu = OptionMenu(layout: processor.hangulLayout)

        super.init(server: server, delegate: delegate, client: inputClient)

        if let inputMethodVersion = getCurrentProjectVersion() {
            logger.debug("팥알 입력기 버전: \(inputMethodVersion)")
        }

        // TIS 입력 소스 변경 알림 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInputSourceChanged),
            name: .inputSourceChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleInputSourceChanged(_ notification: Notification) {
        let endTotal = PerformanceTracerCompat.measureAsync("InputSourceChanged.Total")
        defer { endTotal() }

        guard isControllerActivated else { return }
        syncLayoutIfNeeded()
    }

    private func syncLayoutIfNeeded() {
        guard !isInstanceSynced else { return }
        isInstanceSynced = true
        defer { isInstanceSynced = false }

        let inputMethodID = PerformanceTracerCompat.measure("TIS.getCurrentInputMethodID") {
            getCurrentInputMethodID()
        }

        guard let id = inputMethodID else { return }
        let currentLayout = getInputLayoutID(id: id)

        if currentLayout != layoutName {
            logger.debug("입력 소스 변경 동기화: \(layoutName) → \(currentLayout)")
            updateLayout(to: currentLayout)
        }
    }

    // 입력기가 전환될 때마다 호출됨
    override open func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        isControllerActivated = true

        // 자판 변경 감지 및 업데이트
        syncLayoutIfNeeded()

        // 다른 클라이언트에서 변경된 traits를 동기화
        reloadTraits()

        logger.debug("입력기 서버 시작: \(layoutName)")
    }

    // 자판 변경 시 레이아웃 업데이트
    private func updateLayout(to newLayout: LayoutName) {
        let endTotal = PerformanceTracerCompat.measureAsync("updateLayout.Total")
        defer { endTotal() }

        // 1. 기존 조합 상태 flush (결과는 사용하지 않음 - 이미 deactivate 시 처리됨)
        PerformanceTracerCompat.measure("updateLayout.flushCommit") {
            let _ = processor.flushCommit()
        }

        // 2. 새 레이아웃으로 교체
        layoutName = newLayout
        let hangulLayout = PerformanceTracerCompat.measure("updateLayout.createLayoutInstance") {
            createLayoutInstance(name: layoutName)
        }
        processor = PerformanceTracerCompat.measure("updateLayout.HangulProcessor.init") {
            HangulProcessor(layout: hangulLayout)
        }

        // 3. 저장된 특성 로드
        let traitKey = buildTraitKey(name: layoutName)
        PerformanceTracerCompat.measure("updateLayout.loadActiveOptions") {
            if let loadedTraits = loadActiveOptions(traitKey: traitKey) {
                processor.hangulLayout.traits = loadedTraits
            } else {
                processor.hangulLayout.traits = processor.hangulLayout.availableTraits.subtracting([.글자단위삭제])
            }
        }

        // 4. 메뉴 업데이트
        optionMenu = PerformanceTracerCompat.measure("updateLayout.OptionMenu.init") {
            OptionMenu(layout: processor.hangulLayout)
        }
    }

    // 다른 클라이언트에서 변경된 traits를 동기화
    private func reloadTraits() {
        let traitKey = buildTraitKey(name: layoutName)
        if let loadedTraits = loadActiveOptions(traitKey: traitKey) {
            if processor.hangulLayout.traits != loadedTraits {
                processor.hangulLayout.traits = loadedTraits
                optionMenu = OptionMenu(layout: processor.hangulLayout)
            }
        }
    }

    // 입력기가 비활성화 되면 호출됨
    override open func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
        isControllerActivated = false
        logger.debug("입력기 서버 중단: \(layoutName)")
    }
}
