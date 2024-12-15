//
//  InputKey.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation
import InputMethodKit

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

enum InputStrategy {
    case directInsert
    case swapMarked
}

struct 글자 {
    var chosung: 초성?
    var jungsung: 중성?
    var jongsung: 종성?
}

class HangulProcessor {
    let logger = CustomLogger(category: "InputTextKey")

    var rawChar: String
    var composedHangulChar: Character?

    var previous: [String]
    var preedit: 글자?
    var commit: Character?

    var state: ComposeState = .none
    var hangulStatus: HangulStatus = .none

    let hangulLayout = Han3ShinPcsLayout()

    // var chosung: 초성?
    // var jungsung: 중성?
    // var jongsung: 종성?

    init(layout: String) {
        logger.debug("입력키 처리 클래스 초기화: \(layout)")
        // OS 에서 제공한 원본 문자
        self.rawChar = ""
        // preedit 에 처리중인 rawChar
        self.previous = []
        // previous 를 한글 처리된 문자
        self.preedit = nil
        // 조합 종료된 한글
        self.commit = nil
    }

    deinit {
        logger.debug("입력키 처리 클래스 해제")
    }

    func bindRawCharacter(char: String) -> Bool {
        logger.debug("입력된 문자: \(String(describing: char))")

        // return false if not included chosungMap or jungsungMap or jongsungMap
        if !hangulLayout.chosungMap.keys.contains(char)
            && !hangulLayout.jungsungMap.keys.contains(char)
            && !hangulLayout.jongsungMap.keys.contains(char)
        {
            logger.debug("입력된 문자 \(char) 은 초성, 중성, 종성이 아닙니다.")
            self.rawChar = ""
            return false
        }

        self.rawChar = char
        logger
            .debug(
                "입력: \(self.rawChar) 이전: \(self.previous) 프리에딧: \(String(describing: self.preedit))"
            )
        return true
    }

    func getInputStrategy(client: IMKTextInput) -> InputStrategy {
        // 클라이언트에 따라서 setMarkedText 를 사용할 것인지 insertText 를 사용할 것인지 판단
        let attributes = client.validAttributesForMarkedText() as? [String] ?? []
        logger.debug("validAttributesForMarkedText: \(attributes)")

        // Sok 입력기 참고
        if attributes.contains("NSTextAlternatives")
            || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSFont")
            || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSGlyphInfo")
        {
            logger.debug("입력기 처리 방식: 직결 입력")
            return InputStrategy.directInsert
        }

        logger.debug("입력기 처리 방식: 조합 대치")
        return InputStrategy.swapMarked
    }

    func composeBuffer() -> ComposeState {
        logger
            .debug(
                "입력: \(self.rawChar) 이전: \(self.previous) 프리에딧: \(String(describing: self.preedit))"
            )
        self.previous.append(self.rawChar)

        if let 초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
            self.preedit?.chosung = 초성(rawValue: 초성코드)
        }
        if let 중성코드 = hangulLayout.pickJungsung(by: self.rawChar) {
            self.preedit?.jungsung = 중성(rawValue: 중성코드)
        }
        if let 종성코드 = hangulLayout.pickJongsung(by: self.rawChar) {
            self.preedit?.jongsung = 종성(rawValue: 종성코드)
        }

        return ComposeState.composing
    }

    func getComposedCharacter() -> Character? {
        if let preedit = self.preedit {
            logger.debug("preedit: \(preedit)")
            let composition = combinePreedit(preedit: preedit)
            return Character(UnicodeScalar(composition)!)
        }
        return nil
    }

    func flush() {
        self.previous.removeAll()
        //        self.preedit.removeAll()
        //        self.commit = ""
    }

    // func getComposedChar() -> (ComposeState, String)? {
    //     // HangulStatus.none 인 경우 아무 글자가 들어올 수 있다
    //     if hangulStatus == .none {
    //         if let initialConsonan = hangulLayout.pickChosung(by: self.rawChar) {
    //             self.preedit.append(initialConsonan)
    //             self.state = .composing
    //             self.hangulStatus = .initialConsonant
    //             self.previous.append(self.rawChar)
    //
    //             let char = String(utf16CodeUnits: [initialConsonan], count: 1)
    //             logger.debug("초성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
    //
    //             self.composePreedit()
    //
    //             return (self.state, self.commit)
    //         }
    //
    //         if let medialVowel = hangulLayout.pickJungsung(by: self.rawChar) {
    //             self.preedit.append(medialVowel)
    //             self.state = .composing
    //             self.hangulStatus = .medialVowel
    //             self.previous.append(self.rawChar)
    //
    //             let char = String(utf16CodeUnits: [medialVowel], count: 1)
    //             logger.debug("중성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
    //
    //             self.composePreedit()
    //
    //             return (self.state, self.commit)
    //         }
    //
    //         if let finalConsoan = hangulLayout.pickJongsung(by: self.rawChar) {
    //             self.preedit.append(finalConsoan)
    //             self.state = .composing
    //             self.hangulStatus = .finalConsonant
    //             self.previous.append(self.rawChar)
    //
    //             let char = String(utf16CodeUnits: [finalConsoan], count: 1)
    //             logger.debug("종성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
    //
    //             self.composePreedit()
    //
    //             return (self.state, self.commit)
    //         }
    //     }
    //
    //     // 초성이 세팅된 경우
    //     if hangulStatus == .initialConsonant || hangulStatus == .doubleConsonant {
    //         if let doublable = self.previous.first {
    //             if let doubleConsonant = hangulLayout.pickChosung(by: doublable + self.rawChar) {
    //                 // 겹자음이니까 교체
    //                 self.preedit.removeLast()
    //                 self.preedit.append(doubleConsonant)
    //                 self.state = .composing
    //                 self.hangulStatus = .doubleConsonant
    //
    //                 let char = String(utf16CodeUnits: [doubleConsonant], count: 1)
    //                 logger.debug("이중초성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
    //
    //                 self.composePreedit()
    //                 self.previous.removeAll()
    //
    //                 return (self.state, self.commit)
    //             }
    //         }
    //
    //         if let medialVowel = hangulLayout.pickJungsung(by: self.rawChar) {
    //             self.preedit.append(medialVowel)
    //             self.state = .composing
    //             self.hangulStatus = .medialVowel
    //             self.previous.append(self.rawChar)
    //
    //             let char = String(utf16CodeUnits: [medialVowel], count: 1)
    //             logger.debug("중성 테스트 결과!: \(char), 조합 중: \(self.preedit)")
    //
    //             self.composePreedit()
    //
    //             return (self.state, self.commit)
    //         }
    //     }
    //
    //     // 중성까지 조합된 경우 종성 처리
    //     if self.hangulStatus == .medialVowel {
    //         if let finalVowel = hangulLayout.pickJongsung(by: self.rawChar) {
    //             self.preedit.append(finalVowel)
    //             self.state = .composing
    //             self.hangulStatus = .finalConsonant
    //             self.previous.append(self.rawChar)
    //         }
    //     }
    //
    //     self.state = .none
    //     self.composePreedit()
    //
    //     logger.debug("조합 결과: \(self.commit)(\(self.commit.hash))")
    //
    //     return (self.state, self.commit)
    // }

    // func composePreedit() {
    //     if self.preedit.count > 0 {
    //         self.commit = self.convertFromCodepoint()
    //         logger.debug("조합 된 글자: \(self.commit)")
    //
    //         if self.state == .committed || self.state == .none {
    //             self.preedit = []
    //             self.preedit.removeAll()
    //             self.hangulStatus = .none
    //         }
    //     }
    //     logger.debug("조합 결과: \(self.commit)")
    // }

    // func convertFromCodepoint() -> String {
    //     var result: [unichar] = []
    //
    //     for codePoint in self.preedit {
    //         result.append(codePoint)
    //     }
    //
    //     return String(utf16CodeUnits: result, count: result.count)
    // }
}
