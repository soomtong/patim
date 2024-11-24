//
//  InputKey.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation

enum ComposeState {
    case none
    case initial
    case composing
    case committed
}

enum HangulStatus {
    case none
    case initialConsonant
    case doubleConsonant
    case medialVowel
    case doubleMedialVowel
    case finalConsonant
    case doubleFinalConsonant
}

class HangulProcessor {
    let logger = CustomLogger(category: "InputTextKey")

    var rawChar: String

    var previous: [String]
    var preedit: [unichar]
    var commit: String

    var state: ComposeState = .none
    var hangulStatus: HangulStatus = .none

    let hangulLayout = Han3ShinPcsLayout()

    init(layout: String) {
        logger.debug("입력키 처리 클래스 초기화: \(layout)")
        self.rawChar = ""

        self.previous = []
        self.preedit = []
        self.commit = ""
    }

    deinit {
        logger.debug("입력키 처리 클래스 해제")
    }

    func setKey(string: String) {
        logger.debug("입력된 문자: \(String(describing: string))")

        self.rawChar = string
        logger.debug("입력: \(self.rawChar) 버퍼: \(self.previous)")
    }
    
    func flush() {
        self.previous.removeAll()
        self.preedit.removeAll()
        self.commit = ""
    }

    func getComposedChar() -> (ComposeState, String)? {
        // hangulStatus.none 인 경우 아무 글자가 들어올 수 있다
        if self.hangulStatus == .none {
            if let initialConsonan = hangulLayout.pickChosung(by: self.rawChar) {
                self.preedit.append(initialConsonan)
                self.state = .composing
                self.hangulStatus = .initialConsonant
                self.previous.append(self.rawChar)

                let char = String(utf16CodeUnits: [initialConsonan], count: 1)
                logger.debug("초성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
                
                self.composePreedit()
                
                return (self.state, self.commit)
            }
            
            if let medialVowel = hangulLayout.pickJungsung(by: self.rawChar) {
                self.preedit.append(medialVowel)
                self.state = .composing
                self.hangulStatus = .medialVowel
                self.previous.append(self.rawChar)

                let char = String(utf16CodeUnits: [medialVowel], count: 1)
                logger.debug("중성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
                
                self.composePreedit()
                
                return (self.state, self.commit)
            }
            
            if let finalConsoan = hangulLayout.pickJongsung(by: self.rawChar) {
                self.preedit.append(finalConsoan)
                self.state = .composing
                self.hangulStatus = .finalConsonant
                self.previous.append(self.rawChar)

                let char = String(utf16CodeUnits: [finalConsoan], count: 1)
                logger.debug("종성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
                
                self.composePreedit()
                
                return (self.state, self.commit)
            }
        }
        
        // 초성이 세팅된 경우
        if self.hangulStatus == .initialConsonant {
            if let doublable = self.previous.first {
                if let doubleConsonant = hangulLayout.pickChosung(by: doublable + self.rawChar) {
                    self.preedit.append(doubleConsonant)
                    self.state = .composing
                    self.hangulStatus = .doubleConsonant
                    
                    let char = String(utf16CodeUnits: [doubleConsonant], count: 1)
                    logger.debug("이중초성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
                    
                    self.composePreedit()
                    self.previous.removeAll()
                    
                    return (self.state, self.commit)
                }
            }
            
            if let medialVowel = hangulLayout.pickJungsung(by: self.rawChar) {
                self.preedit.append(medialVowel)
                self.state = .composing
                self.hangulStatus = .medialVowel
                self.previous.append(self.rawChar)
                
                let char = String(utf16CodeUnits: [medialVowel], count: 1)
                logger.debug("중성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
                
                self.composePreedit()
                
                return (self.state, self.commit)
            }
        }
        
        // 중성까지 조합된 경우
        if self.hangulStatus == .medialVowel {
            if let finalVowel = hangulLayout.pickJongsung(by: self.rawChar) {
                self.preedit.append(finalVowel)
                self.state = .composing
                self.hangulStatus = .finalConsonant
                self.previous.append(self.rawChar)
            }
        }

        self.state = .none
        self.composePreedit()

        logger.debug("조합 결과: \(self.commit)")

        return (self.state, self.commit)
    }

    func composePreedit() {
        if self.preedit.count > 0 {
            self.commit = self.convertFromCodepoint()
            logger.debug("조합 된 글자: \(self.commit)")
            
            if self.state == .committed || self.state == .none {
                self.preedit = []
                self.preedit.removeAll()
                self.hangulStatus = .none
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
