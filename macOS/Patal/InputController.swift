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

    // let layoutSwitcher = LayoutSwitcher()
    let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

    override func inputText(
        _ string: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!
    ) -> Bool {
        // 재사용하면 성능이 오를까? 클래스 생성을 한 번만 하기로
        processor.setKey(string: string, keyCode: keyCode, flags: flags)

        // esc 키를 눌러 라틴 자판으로 변경하는 기능은 karabiner 세팅을 사용하기로 한다.
        // 이 기능은 보류.
        if processor.isEscaped() {
            // layoutSwitcher.changeLayout()
            return false
        }

        guard let client = sender as? IMKTextInput else {
            return false
        }

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
