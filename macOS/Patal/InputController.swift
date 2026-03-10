//
//  InputController.swift
//  Patal
//
//  Created by TemplarAssassin on 2022/03/13.
//

import Foundation
import IMKSwift

@objc(PatIMKController)
class InputController: IMKInputSessionController {
    // 비즈니스 로직 객체를 클라이언트별로 관리
    var context: InputControllerContext!

    // 컨텍스트 프로퍼티에 대한 편의 접근자
    internal var logger: CustomLogger { context.logger }
    internal var layoutName: LayoutName {
        get { context.layoutName }
        set { context.layoutName = newValue }
    }
    internal var optionMenu: OptionMenu {
        get { context.optionMenu }
        set { context.optionMenu = newValue }
    }
    var processor: HangulProcessor {
        get { context.processor }
        set { context.processor = newValue }
    }

    // 현재 컨트롤러가 활성 상태인지 추적
    private(set) var isControllerActivated: Bool = false
    // 동기화 중복 방지 플래그
    private(set) var isInstanceSynced: Bool = false

    // 빠른마침표: 보류 스페이스 자동 플러시 타이머
    var pendingSpaceTimer: DispatchWorkItem?

    override init(server: IMKServer, delegate: Any?, client inputClient: any IMKTextInput) {
        super.init(server: server, delegate: delegate, client: inputClient)

        let inputMethodID = getCurrentInputMethodID() ?? "InputmethodHan3P3"
        let currentLayout = getInputLayoutID(id: inputMethodID)
        context = InputControllerContext(controller: self, layoutName: currentLayout)
        logger.debug("팥알 입력기 자판: \(layoutName)")
        logger.debug("팥알 입력기 처리기: \(processor)")

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
    override func activateServer(_ sender: any IMKTextInput) {
        super.activateServer(sender)
        isControllerActivated = true

        // 자판 변경 감지 및 업데이트
        syncLayoutIfNeeded()

        // 다른 클라이언트에서 변경된 traits를 동기화
        context.reloadTraits()

        logger.debug("입력기 서버 시작: \(layoutName)")
    }

    // 자판 변경 시 레이아웃 업데이트
    private func updateLayout(to newLayout: LayoutName) {
        let endTotal = PerformanceTracerCompat.measureAsync("updateLayout.Total")
        defer { endTotal() }

        context.updateLayout(to: newLayout)
    }

    // 입력기가 비활성화 되면 호출됨
    override func deactivateServer(_ sender: any IMKTextInput) {
        super.deactivateServer(sender)
        isControllerActivated = false
        logger.debug("입력기 서버 중단: \(layoutName)")
    }
}
