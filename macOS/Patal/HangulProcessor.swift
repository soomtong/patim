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

    var previous: [String]
    var preedit: 글자
    var 완성: String?

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
    }

    deinit {
        logger.debug("입력키 처리 클래스 해제")
    }

    /**
     입력 방식 강제 지정
     */
    func getInputStrategy(client: IMKTextInput) -> InputStrategy {
        // 클라이언트에 따라서 setMarkedText 를 사용할 것인지 insertText 를 사용할 것인지 판단
        let attributes = client.validAttributesForMarkedText() as? [String] ?? []
        // logger.debug("validAttributesForMarkedText: \(attributes)")

        // Sok 입력기 참고
        if attributes.contains("NSTextAlternatives")
            || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSFont")
            || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSGlyphInfo")
        {
            // logger.debug("입력기 처리 방식: 직결 입력")
            return InputStrategy.directInsert
        }

        // logger.debug("입력기 처리 방식: 조합 대치")
        return InputStrategy.swapMarked
    }

    /**
     조합 가능한 입력인지 검증한다.
     */
    func verifyCombosable(_ s: String) -> Bool {
        return hangulLayout.chosungMap.keys.contains(s)
            || hangulLayout.jungsungMap.keys.contains(s)
            || hangulLayout.jongsungMap.keys.contains(s)
    }

    /**
     조합 가능한 문자가 들어온다. 다시 검수할 필요는 없음. 겹자음/겹모음이 있을 수 있기 때문에 previous 를 기준으로 운영.
     previous=raw char 조합, preedit=조합중인 한글, commit=조합된 한글
     */
    func composeBuffer() -> ComposeState {
        logger.debug("- 이전: \(self.previous) 프리에딧: \(String(describing: self.preedit))")
        logger.debug("- 입력: \(self.rawChar)")

        let status = (self.preedit.chosung, self.preedit.jungsung, self.preedit.jongsung)
        switch status {
        case (nil, nil, nil):
            /* "" -> "ㄱ" */
            print("시작! 초성을 채움")
            self.previous.append(self.rawChar)

            let 초성코드 = hangulLayout.pickChosung(by: self.previous.joined())
            if 초성코드 != nil {
                self.preedit.chosung = 초성(rawValue: 초성코드!)

                return ComposeState.composing
            }

            /* "" -> "ㅏ" */
            print("시작? 중성을 채움")
            let 중성코드 = hangulLayout.pickJungsung(by: self.previous.joined())
            if 중성코드 != nil {
                self.preedit.jungsung = 중성(rawValue: 중성코드!)

                return ComposeState.composing
            }

            /* "" -> "ㄴ" */
            print("시작? 종성을 채움")
            let 종성코드 = hangulLayout.pickJongsung(by: self.previous.joined())
            if 종성코드 != nil {
                self.preedit.jongsung = 종성(rawValue: 종성코드!)

                return ComposeState.composing
            }
        case (_, nil, nil):
            /* "ㄱ" -> "ㄲ", "ㄱ" -> "ㄱㄴ", "ㄲ" -> "ㅋ" */
            print("초성이 있는데 또 초성이 온 경우, 또는 연타해서 다른 글자를 만들 경우")
            self.previous.append(self.rawChar)

            let 복합초성코드 = hangulLayout.pickChosung(by: self.previous.joined())
            if 복합초성코드 != nil {
                self.preedit.chosung = 초성(rawValue: 복합초성코드!)

                return ComposeState.composing
            }

            /* "ㄱ" + "ㅏ" -> "가" */
            print("중성이 왔다면! \(self.previous)")
            self.previous.removeAll()
            self.previous.append(self.rawChar)
            let 중성코드 = hangulLayout.pickJungsung(by: self.previous.joined())
            print("중성인가? \(String(describing: 중성코드))")
            if 중성코드 != nil {
                self.preedit.jungsung = 중성(rawValue: 중성코드!)

                return ComposeState.composing
            }

            /* "ㄱ" + "ㄱ" -> "ㄲ" */
            print("이제는 새로운 초성이 온 거임 \(self.rawChar)")
            self.previous.removeAll()
            self.previous.append(self.rawChar)

            let 초성코드 = hangulLayout.pickChosung(by: self.previous.joined())
            if 초성코드 != nil {
                self.preedit.chosung = 초성(rawValue: 초성코드!)
                self.완성 = self.getComposed()

                return ComposeState.committed
            }
        case (nil, _, nil):
            print("중성이 있는데 또 중성이 온 경우")
        case (_, _, nil):
            print("받침 없는 글자 이후 다시 초성이?")
            /* "ㄴ" + "ㅗ" + "ㄹ" -> "노ㄹ" */
            let 초성코드 = hangulLayout.pickChosung(by: self.rawChar)
            if 초성코드 != nil {
                print("이전 글자를 commit 해야 함")
                self.완성 = self.getComposed()
                self.commit()

                self.preedit.chosung = 초성(rawValue: 초성코드!)

                return ComposeState.committed
            }

            print("초성과 중성이 있는데 중성이 또 왔다")
            /* "ㅁ" + "ㅗ" + "ㅏ" -> "뫄" */
            self.previous.append(self.rawChar)

            let 복합중성코드 = hangulLayout.pickJungsung(by: self.previous.joined())
            if 복합중성코드 != nil {
                self.preedit.jungsung = 중성(rawValue: 복합중성코드!)

                return ComposeState.composing
            }

            print("종성이 왔다면!")
            /* "ㄱ" + "ㅏ" + "ㅇ" -> "강" */
            self.previous.removeAll()
            self.previous.append(self.rawChar)

            let 종성코드 = hangulLayout.pickJongsung(by: self.previous.joined())
            print("종성인가? \(String(describing: 종성코드))")
            if 종성코드 != nil {
                self.preedit.jongsung = 종성(rawValue: 종성코드!)

                return ComposeState.composing
            }
        case (_, _, _):
            print("초성, 중성, 종성이 있는데?")
            print("겹자음 종성이 있는 경우만 처리")
            /* "ㅂ" + "ㅏ" + "ㄱ" + "ㄱ" -> "밖" */
            self.previous.append(self.rawChar)

            let 복합종성코드 = hangulLayout.pickJongsung(by: self.previous.joined())
            print("복합 종성인가? \(String(describing: 복합종성코드))")
            if 복합종성코드 != nil {
                self.preedit.jongsung = 종성(rawValue: 복합종성코드!)

                return ComposeState.committed
            }

            self.완성 = self.getComposed()
            self.commit()

            let _ = self.composeBuffer()
            return ComposeState.committed
        }

        print("preedit: \(String(describing: self.preedit))")

        return ComposeState.committed
    }

    func getComposed() -> String? {
        let hangulComposer = HangulComposer(
            chosungPoint: preedit.chosung,
            jungsungPoint: preedit.jungsung,
            jongsungPoint: preedit.jongsung
        )
        if let composition = hangulComposer?.getSyllable() {
            logger.debug("조합됨: \(String(describing: composition)) (\(preedit))")
            return String(composition)
        }

        return nil
    }

    func commit() {
        self.previous.removeAll()
        self.preedit.chosung = nil
        self.preedit.jungsung = nil
        self.preedit.jongsung = nil
    }

    func flush() {
        self.rawChar = ""
        self.previous.removeAll()
        self.preedit.chosung = nil
        self.preedit.jungsung = nil
        self.preedit.jongsung = nil
        self.완성 = nil
    }

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
