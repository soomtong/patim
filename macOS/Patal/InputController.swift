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

    override func inputText(_ string: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!) -> Bool {
        let key = InputTextKey(string: string, keyCode: keyCode, flags: flags)

        if key.isEscaped() {
            switchLatinKeyLayout()
        }

        guard let client = sender as? IMKTextInput else {
            return false
        }

        guard let char = key.getChar() else {
            return false
        }

        client.insertText(char, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))

        return true
    }

    //    override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //        NSLog("hello patal input method: \(event)")
    //        return false
    //    }
}
