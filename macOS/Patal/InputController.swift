//
//  InputController.swift
//  Patal
//
//  Created by TemplarAssassin on 2022/03/13.
//
import os.log

import Foundation
import InputMethodKit

@objc(PatInputController)
internal class InputController: IMKInputController {
    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        os_log("입력된 문자: \(string)")
        guard let client = sender as? IMKTextInput else {
            return false
        }

        let defaultChar = "ㅎ하한글?횂!";
        client.insertText(defaultChar, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        return true
    }

//    override func inputText(_ string: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!) -> Bool {
//        super.inputText(string, key: keyCode, modifiers: flags, client: sender)
//    }

//    override func handle(_ event: NSEvent, client sender: Any) -> Bool {
//        NSLog("hello patal input method: \(event)")
//        return false
//    }
}
