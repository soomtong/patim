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

        // client 현재 입력기를 사용하는 클라이언트 임. 예를 들면 com.googlecode.iterm2
        logger.debug("this client: \(client.bundleIdentifier() ?? "")")

        if !processor.verifyCombosable(char: string) {
            return false
        }

        processor.rawChar = string

        let strategy = processor.getInputStrategy(client: client)
        let state = processor.composeBuffer()
        let character = processor.getComposedCharacter()

        // state 에 따라서 조합된거 조합중인거를 구분하고
        // 선택된 strategy 에 따라서 insert 또는 setMark 를 고르고 조합된 한글 글자를 출력하기

        logger.debug("strategy: \(String(describing: strategy))")
        logger.debug("state: \(String(describing: state))")
        logger.debug("character: \(String(describing: character))")

        // 입력 테스트
        let defaultRange = NSRange(location: NSNotFound, length: 0)
        let selectionRange = NSRange(location: 0, length: 0)
        let replacementRange = NSRange(location: NSNotFound, length: NSNotFound)
        logger.debug(
            "선택범위: \(String(describing: selectionRange)), 교체범위: \(String(describing: replacementRange))"
        )

        client.insertText("강산", replacementRange: defaultRange)

        return true

        // 조합 테스트
        // let defaultRange = NSRange(location: NSNotFound, length: 0)
        // let selectionRange = NSRange(location: 0, length: 0)
        // let replacementRange = NSRange(location: NSNotFound, length: NSNotFound)
        // logger.debug(
        //     "선택범위: \(String(describing: selectionRange)), 교체범위: \(String(describing: replacementRange))"
        // )
        //
        // client
        //     .setMarkedText(
        //         "강산", selectionRange: defaultRange, replacementRange: defaultRange
        //     )
        //
        // return true
    }

    override func commitComposition(_ sender: Any!) {
        processor.flush()
    }

    //override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //    NSLog("hello patal input method: \(event)")
    //    return false
    //}
}
