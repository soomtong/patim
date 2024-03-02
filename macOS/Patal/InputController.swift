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

    let key = InputTextKey(string: "", keyCode: 0, flags: 0)
    let layoutSwitcher = LayoutSwitcher()

    override func inputText(_ string: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!) -> Bool {
        // 재사용하면 성능이 오를까? 클래스 생성을 한 번만 하기로
        key.bind(string: string, keyCode: keyCode, flags: flags)

        if key.isEscaped() {
            layoutSwitcher.changeLayout(layout: "ABC")
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
