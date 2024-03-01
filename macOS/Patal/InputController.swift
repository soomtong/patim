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
    /*
    // 특수 키 - ESC ENTER SHIFT 등의 입력을 알 수 없음
    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        os_log("입력된 문자: \(string)")
        guard let client = sender as? IMKTextInput else {
            return false
        }

        let defaultChar = "ㅎ하한글?횂!";
        client.insertText(defaultChar, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        return true
    }
    */

    private let escKeyCode = 53

    override func inputText(_ string: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!) -> Bool {
        // 키코드 목록 https://eastmanreference.com/complete-list-of-applescript-key-codes
        debug("입력된 문자: \(String(describing: string)), \(keyCode), \(flags)")

        if keyCode == escKeyCode {
            debug("이거야 ESC!!!")
        }

        guard let client = sender as? IMKTextInput else {
            return false
        }

        let defaultChar = "ㅎ하한글?횂!";
        client.insertText(defaultChar, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        return true
    }

    //    override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //        NSLog("hello patal input method: \(event)")
    //        return false
    //    }
}
