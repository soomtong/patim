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

    var rawChar: String
    var keyCode: Int
    var flags: Int

    var buffer: ComposedChar
    var preedit: [unichar]
    var commit: String

    private var state: ComposeState = .none

    let hangulLayout = Han3ShinPcsLayout()

    init(layout: String) {
        logger.debug("입력키 처리 클래스 초기화: \(layout)")
        self.rawChar = ""
        self.keyCode = 0
        self.flags = 0
        
        self.buffer = ComposedChar(char: "", keyCode: 0, flags: 0)
        self.preedit = []
        self.commit = ""
    }

    deinit {
        logger.debug("입력키 처리 클래스 해제")
    }

    func setKey(string: String, keyCode: Int, flags: Int) {
        logger.debug("입력된 문자: \(String(describing: string)), \(keyCode), \(flags)")

        self.rawChar = string
        self.keyCode = keyCode
        self.flags = flags

        self.buffer = ComposedChar(char: self.rawChar, keyCode: self.keyCode, flags: self.flags)
        logger.debug("버퍼: \(self.buffer.char)")
    }

    func getComposedChar() -> (ComposeState, String)? {
        // 키가 들어오면 조합 시작
        // kf -> 가
        if let initialConsonan = hangulLayout.pickChosung(by: self.buffer.char) {
            self.preedit.append(initialConsonan)
            self.state = .composing
            let char = String(utf16CodeUnits: [initialConsonan], count: 1)
             logger.debug("초성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
            return (self.state, char)
        }
        
        if let initialVowel = hangulLayout.pickJungsung(by: self.buffer.char) {
            self.preedit.append(initialVowel)
            self.state = .composing
            let char = String(utf16CodeUnits: [initialVowel], count: 1)
            logger.debug("중성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
            return (self.state, char)
        }
        
        self.composePreedit()
        
        logger.debug("조합 결과: \(self.commit)")
        return (self.state, self.commit)
    }
    
    func composePreedit() {
        if self.preedit.count > 0 {
                // make unicode hangul char by unichar code point
            self.commit = self.convertFromCodepoint()
            logger.debug("조합 된 글자: \(self.commit)")
            if self.state == .committed {
                self.preedit = []
            }
        }
        logger.debug("조합 결과: \(self.commit)")
    }
    
    func convertFromCodepoint() -> String {
        var result: [unichar] = []
        
        for codePoint in self.preedit {
            result.append(codePoint)
        }
        
        return String(utf16CodeUnits: result, count: result.count)
    }
}
