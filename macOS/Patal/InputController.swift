//
//  InputController.swift
//  Patal
//
//  Created by TemplarAssassin on 2022/03/13.
//

import Foundation
import InputMethodKit

@objc(PatInputController)
class InputController: IMKInputController {
    let logger = CustomLogger(category: "InputController")

    let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
    }

    override open func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        logger.debug("입력기 서버 시작")
        if let inputMethodID = getCurrentInputMethodID() {
            logger.debug("팥알 입력기 자판: \(inputMethodID)")
        }
    }

    override open func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
        logger.debug("입력기 서버 중단")
    }

    // 이 입력 방법은 OS 에서 백스페이스, 엔터 등을 처리함. 즉, 완성된 키코드를 제공함.
    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        guard let client = sender as? IMKTextInput else {
            return false
        }

        if !processor.verifyCombosable(string) {
            return false
        }

        // client 현재 입력기를 사용하는 클라이언트 임. 예를 들면 com.googlecode.iterm2
        logger.debug("클라이언트: \(client.bundleIdentifier() ?? "")")
        let strategy = processor.getInputStrategy(client: client)
        logger.debug("전략: \(String(describing: strategy))")

        processor.rawChar = string

        let state = processor.composeBuffer()
        let character = processor.getComposedCharacter()

        // -- start
        let defaultRange = NSRange(location: NSNotFound, length: 0)
        let selectionRange = NSRange(location: 0, length: 0)
        let replacementRange = NSRange(location: NSNotFound, length: NSNotFound)
        logger.debug(
            "선택범위: \(String(describing: selectionRange)), 교체범위: \(String(describing: replacementRange))"
        )
        // client.insertText("강산", replacementRange: defaultRange)
        // processor.flush()
        // return true
        // -- end

        let debug =
            "검수: \(String(describing: state)) \(String(describing: character))"
        if character != nil {
            // logger.debug(debug)
            // state 와 strategy 로 setMarkedText 와 insertText 를 구분
            switch (state, strategy) {
            case (ComposeState.committed, InputStrategy.directInsert):
                processor.flush()
                client.insertText(String(character!), replacementRange: defaultRange)
            case (ComposeState.composing, InputStrategy.directInsert):
                client.insertText(String(character!), replacementRange: defaultRange)
            case (ComposeState.committed, InputStrategy.swapMarked):
                processor.flush()
                client.insertText(String(character!), replacementRange: defaultRange)
            case (ComposeState.composing, InputStrategy.swapMarked):
                client
                    .setMarkedText(
                        String(character!),
                        selectionRange: defaultRange,
                        replacementRange: replacementRange
                    )
            default:
                processor.flush()
            }

            return true
        }

        processor.flush()
        return false
    }

    override func commitComposition(_ sender: Any!) {
        processor.flush()
    }

    //override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //    NSLog("hello patal input method: \(event)")
    //    return false
    //}
}
