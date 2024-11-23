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

enum ComposeState {
    case none
    case initial
    case composing
    case committed
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

    var buffer: ComposedChar
    var preedit: [unichar]
    var commit: [unichar]

    private var state: ComposeState = .none

    let hangulLayout = Han3ShinPcsLayout()

    init(layout: String) {
        logger.debug("입력키 처리 클래스 초기화: \(layout)")
        self.string = ""
        self.keyCode = 0
        self.flags = 0
        
        self.buffer = ComposedChar(char: "", keyCode: 0, flags: 0)
        self.preedit = []
        self.commit = []
    }

    deinit {
        logger.debug("입력키 처리 클래스 해제")
    }

    func setKey(string: String, keyCode: Int, flags: Int) {
        logger.debug("입력된 문자: \(String(describing: string)), \(keyCode), \(flags)")

        self.string = string
        self.keyCode = keyCode
        self.flags = flags

        self.buffer = ComposedChar(char: self.string, keyCode: self.keyCode, flags: self.flags)
        logger.debug("버퍼: \(self.buffer.char)")
    }

    func getComposedChar() -> (ComposeState, String)? {
        // 키가 들어오면 조합 시작
        // kf -> 가
        if let initialConsonan = hangulLayout.pickChosung(by: self.buffer.char) {
            self.preedit.append(initialConsonan)
            self.state = .composing
            let char = String(utf16CodeUnits: [initialConsonan], count: 1)
            return (self.state, char)
        }
        
        if let initialVowel = hangulLayout.pickJungsung(by: self.buffer.char) {
            self.preedit.append(initialVowel)
            self.state = .composing
            let char = String(utf16CodeUnits: [initialVowel], count: 1)
            return (self.state, char)
        }

        // todo: 각각의 낱자를 조합하는 과정이 필요함
        // self.commit = self.preedit
        //            return "\(initialConsonant)\(vowelComposed)"
        // let utf16CodeUnits: [unichar] = [chosung.rawValue]
        // return (chosung, String(utf16CodeUnits: utf16CodeUnits, count: utf16CodeUnits.count))
        logger.debug("조합 대상: \(self.preedit)")
        return (self.state, "조합 중!")
    }
}
