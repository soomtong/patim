//
//  InputController.swift
//  Patal
//
//  Created by TemplarAssassin on 2022/03/13.
//

import Foundation
import InputMethodKit

@objc(PatInputController)
internal class InputController: IMKInputController {
    let logger = CustomLogger(category: "InputController")

    let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

    // 이 입력 방법은 OS 에서 백스페이스, 엔터 등을 처리함. 즉, 완성된 키코드를 제공함.
    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        guard let client = sender as? IMKTextInput else {
            return false
        }

        processor.setKey(string: string)

        guard let (_, char) = processor.getComposedChar() else {
            return false
        }

        // logger.debug(
        // "inputText: \(string), keyCode: \(keyCode), flags: \(flags), state: \(state), char: \(char)"
        // )
        if processor.state == .composing {
            let selectionRange = NSRange(location: 0, length: 0)
            let replacementRange = NSRange(location: 0, length: 0)
            client.setMarkedText(
                char, selectionRange: selectionRange, replacementRange: replacementRange)
        } else {
            client.insertText(
                char, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        }

        return true
    }

    override func commitComposition(_ sender: Any!) {
        processor.flush()
    }

    //override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //    NSLog("hello patal input method: \(event)")
    //    return false
    //}
}
