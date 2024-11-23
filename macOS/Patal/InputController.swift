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

    override func inputText(
        _ string: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!
    ) -> Bool {
        guard let client = sender as? IMKTextInput else {
            return false
        }
        
        processor.setKey(string: string, keyCode: keyCode, flags: flags)

        guard let char = processor.getComposedChar() else {
            return false
        }

        // 조합중인 글자를 처리하기 위해, 백스페이스를 처리하기 위해 커서를 움직여야 함.
        // 이 조합 조건들은 모두 테스트 케이스를 먼저 디자인할 것
        client.insertText(char, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))

        return true
    }

    //override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //    NSLog("hello patal input method: \(event)")
    //    return false
    //}
}
