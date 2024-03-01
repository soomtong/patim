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
    let customLogger = CustomLogger(category: "Input Controller")

    // 키코드 목록 https://eastmanreference.com/complete-list-of-applescript-key-codes
    private let escKeyCode = 53

    override func inputText(_ string: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!) -> Bool {
        // 특수 키 - ESC ENTER SHIFT 등의 입력을 위해 keyCode 를 받아야 함
        customLogger.debug("입력된 문자: \(String(describing: string)), \(keyCode), \(flags)")

        if keyCode == escKeyCode {
            customLogger.debug("이거야 ESC!!!")
        }

        guard let client = sender as? IMKTextInput else {
            return false
        }

        let defaultChar = "ㅎ하한글?횂!"; client.insertText(defaultChar, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        return true
    }

    //    override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //        NSLog("hello patal input method: \(event)")
    //        return false
    //    }
}
