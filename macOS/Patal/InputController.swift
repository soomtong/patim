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

    // 클라이언트 하나 당 하나의 입력기 레이아웃 인스턴스가 사용됨
    internal var layoutName: LayoutName
    internal var optionMenu: OptionMenu

    var processor: HangulProcessor

    // 클래스 생성이 하나의 인스턴스에서 이루어지기 때문에 여러개의 Patal 입력기를 동시에 사용할 수 없음.
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
            processor.hangulLayout.traits = processor.hangulLayout.availableTraits
        }

        optionMenu = OptionMenu(layout: processor.hangulLayout)

        super.init(server: server, delegate: delegate, client: inputClient)

        if let inputMethodVersion = getCurrentProjectVersion() {
            logger.debug("팥알 입력기 버전: \(inputMethodVersion)")
        }
    }

    // 입력기가 전환될 때마다 호출됨
    override open func activateServer(_ sender: Any!) {
        super.activateServer(sender)

        // 자판 변경 감지 및 업데이트
        if let inputMethodID = getCurrentInputMethodID() {
            let currentLayout = getInputLayoutID(id: inputMethodID)

            if currentLayout != layoutName {
                logger.debug("자판 변경 감지: \(layoutName) → \(currentLayout)")
                updateLayout(to: currentLayout)
            }
        }

        logger.debug("입력기 서버 시작: \(layoutName)")
    }

    // 자판 변경 시 레이아웃 업데이트
    private func updateLayout(to newLayout: LayoutName) {
        // 1. 기존 조합 상태 flush (결과는 사용하지 않음 - 이미 deactivate 시 처리됨)
        let _ = processor.flushCommit()

        // 2. 새 레이아웃으로 교체
        layoutName = newLayout
        let hangulLayout = createLayoutInstance(name: layoutName)
        processor = HangulProcessor(layout: hangulLayout)

        // 3. 저장된 특성 로드
        let traitKey = buildTraitKey(name: layoutName)
        if let loadedTraits = loadActiveOptions(traitKey: traitKey) {
            processor.hangulLayout.traits = loadedTraits
        } else {
            processor.hangulLayout.traits = processor.hangulLayout.availableTraits
        }

        // 4. 메뉴 업데이트
        optionMenu = OptionMenu(layout: processor.hangulLayout)
    }

    // 입력기가 비활성화 되면 호출됨
    override open func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
        logger.debug("입력기 서버 중단: \(layoutName)")
    }
}
