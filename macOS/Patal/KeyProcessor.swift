//
//  InputKey.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation

struct ComposedChar {
    var char: String
    var keyCode: Int
    var flags: Int
}

// 키코드 목록 https://eastmanreference.com/complete-list-of-applescript-key-codes
let CMD_FLAG = 1_048_576
let CTRL_FLAG = 262144
let OPT_FLAG = 524288
let SHIFT_FLAG = 131072
let ESC_KEYCODE = 53

class HangulProcessor {
    let logger = CustomLogger(category: "InputTextKey")

    var string: String
    var keyCode: Int
    var flags: Int

    var buffer: [ComposedChar]
    var preedit: [unichar]
    var commit: [unichar]
    var layout: Han3ShinPcsLayout

    init(layout: String) {
        logger.debug("입력키 처리 클래스 초기화: \(layout)")
        self.string = ""
        self.keyCode = 0
        self.flags = 0
        self.buffer = []
        self.preedit = []
        self.commit = []
        self.layout = Han3ShinPcsLayout()
    }

    func setKey(string: String, keyCode: Int, flags: Int) {
        // 특수 키 - ESC ENTER SHIFT 등의 입력을 위해 keyCode 를 받아야 함
        logger.debug("입력된 문자: \(String(describing: string)), \(keyCode), \(flags)")

        self.string = string
        self.keyCode = keyCode
        self.flags = flags

        let char = ComposedChar(char: self.string, keyCode: self.keyCode, flags: self.flags)
        self.buffer.append(char)
        logger.debug("버퍼: \(self.buffer.count) \(char.char)")
    }

    func isEscaped() -> Bool {
        if self.keyCode == ESC_KEYCODE && self.flags == 0 {
            return true
        }
        return false
    }

    func getComposedChar() -> String? {
        // 초성이 들어오면 조합 시작
        if let char = self.buffer.first {
            let composed = self.layout.pickChosung(by: char.char)
            self.buffer.removeFirst()
            return composed
        }
        return nil
    }
}
