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
    override func handle(_ event: NSEvent, client sender: Any) -> Bool {
        NSLog("hello patal input method: \(event)")
        return false
    }
}
