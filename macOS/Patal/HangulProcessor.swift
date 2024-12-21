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
    var preedit: 글자
    var commit: Character?

    var state: ComposeState = .none
    var hangulStatus: HangulStatus = .none

    let hangulLayout = Han3ShinPcsLayout()

    init(layout: String) {
        logger.debug("입력키 처리 클래스 초기화: \(layout)")
        // OS 에서 제공한 원본 문자
        self.rawChar = ""
        // preedit 에 처리중인 rawChar
        self.previous = []
        // previous 를 한글 처리된 문자
        self.preedit = 글자()
        // 조합 종료된 한글
        self.commit = nil
    }

    deinit {
        logger.debug("입력키 처리 클래스 해제")
    }

    /**
     조합 가능한 입력인지 검증한다.
     */
    func verifyCombosable(_ s: String) -> Bool {
        logger.debug("입력된 문자: \(String(describing: s))")

        let isValid =
            hangulLayout.chosungMap.keys.contains(s)
            || hangulLayout.jungsungMap.keys.contains(s)
            || hangulLayout.jongsungMap.keys.contains(s)

        if isValid {
            return true
        }

        logger.debug("입력된 문자 \(s) 은 초성, 중성, 종성이 아닙니다.")
        return false
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

    /**
     조합 가능한 문자가 들어온다. 다시 검수할 필요는 없음. 겹자음/겹모음이 있을 수 있기 때문에 previous 를 기준으로 운영.
     previous=raw char 조합, preedit=조합중인 한글, commit=조합된 한글
     */
    func composeBuffer() -> ComposeState {
        logger.debug("입력: \(self.rawChar)")
        logger.debug("-- 이전: \(self.previous) 프리에딧: \(String(describing: self.preedit))")

        //        let 중성코드 = hangulLayout.pickJungsung(by: self.previous.joined())
        //        let 종성코드 = hangulLayout.pickJongsung(by: self.previous.joined())

        /* "" -> "ㄱ" */
        if self.preedit.chosung == nil {
            print("시작! 초성을 채움")
            self.previous = [self.rawChar]
            let 초성코드 = hangulLayout.pickChosung(by: self.previous.joined())
            self.preedit.chosung = 초성(rawValue: 초성코드!)

            return ComposeState.composing
        }

        /* "ㄱ" -> "ㄲ", "ㄱ" -> "ㄱㄴ", "ㄲ" -> "ㅋ" */
        if self.preedit.chosung != nil {
            print("\(self.previous): 초성이 있는데 또 초성이 온 경우, 또는 연타해서 다른 글자를 만들 경우 kkk 를 누르면 ㅋ 을 제공할 수 있음")
            self.previous.append(self.rawChar)
            print("--- 다음: \(self.previous)")
            let 복합초성코드 = hangulLayout.pickChosung(by: self.previous.joined())
            if 복합초성코드 != nil {
                self.preedit.chosung = 초성(rawValue: 복합초성코드!)

                return ComposeState.composing
            }

            print("이제는 새로운 초성이 온 거임 \(self.rawChar)")
            self.previous.removeAll()
            self.previous.append(self.rawChar)
            let 초성코드 = hangulLayout.pickChosung(by: self.previous.joined())
            if 초성코드 != nil {
                self.preedit.chosung = 초성(rawValue: 초성코드!)
                return ComposeState.committed
            }
        }

        //        if 중성코드 != nil {
        //            if self.preedit.chosung == nil {
        //                return ComposeState.composing
        //            }
        //
        //            if self.preedit.jungsung == nil {
        //                self.preedit.jungsung = 중성(rawValue: 중성코드!)
        //                return ComposeState.composing
        //            }
        //
        //            if self.preedit.jongsung == nil {
        //                self.preedit.jongsung = 종성(rawValue: 종성코드!)
        //                return ComposeState.composing
        //            }
        //        }
        //
        //        if self.preedit.chosung != nil {
        //            if self.preedit.jungsung != nil {
        //                if self.preedit.jongsung != nil {
        //                    self.preedit.jongsung = nil
        //                }
        //                self.preedit.jungsung = nil
        //            }
        //            self.preedit.chosung = nil
        //        }

        print("preedit: \(String(describing: self.preedit))")

        return ComposeState.composing
    }

    func getComposedCharacter() -> Character? {
        logger.debug("조합중 preedit: \(preedit)")
        let hangulComposer = HangulComposer(
            chosungPoint: preedit.chosung, jungsungPoint: preedit.jungsung,
            jongsungPoint: preedit.jongsung
        )
        let composition = hangulComposer?.getSyllable()
        logger.debug("조합됨 composition: \(String(describing: composition))")
        return composition
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
