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
    internal let layoutName: LayoutName
    internal let optionMenu: OptionMenu

    let processor: HangulProcessor

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
    @MainActor
    override open func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        logger.debug("입력기 서버 시작: \(layoutName)")
    }

    // 입력기가 비활성화 되면 호출됨
    @MainActor
    override open func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
        logger.debug("입력기 서버 중단: \(layoutName)")
    }

    //override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //    NSLog("hello patal input method: \(event)")
    //    return false
    //}
}
