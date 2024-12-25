//
//  InputKey.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation
import InputMethodKit

/// 조합 처리 후 결과를 담고 있음; 처리 과정의 상태는 preedit 의 상태를 판단하면 됨
enum CommitState {
    case none
    case composing
    case committed
}

/// insertText 와 setMarkedText 호출을 위한 조건 구분
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

    /// OS 에서 제공하는 문자
    var rawChar: String

    /// preedit 에 처리중인 rawChar 배열: 겹낱자나 모아치기를 위한 버퍼
    var previous: [String]
    /// previous 를 한글 처리된 문자
    var preedit: 글자
    /// 조합 종료된 한글
    var 완성: String?

    let hangulLayout: HangulAutomata

    init(layout: HangulAutomata) {
        logger.debug("입력키 처리 클래스 초기화: \(layout)")
        self.rawChar = ""
        self.previous = []
        self.preedit = 글자()

        self.hangulLayout = layout
    }

    deinit {
        logger.debug("입력키 처리 클래스 해제")
    }

    /// 입력 방식 강제 지정
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

    /// 처리 가능한 입력인지 검증한다.
    func verifyProcessable(_ s: String) -> Bool {
        return hangulLayout.chosungMap.keys.contains(s)
            || hangulLayout.jungsungMap.keys.contains(s)
            || hangulLayout.jongsungMap.keys.contains(s)
            || hangulLayout.nonSyllableMap.keys.contains(s)
    }

    /// 한글 조합 가능한 입력인지 검증한다.
    func verifyCombosable(_ s: String) -> Bool {
        return hangulLayout.chosungMap.keys.contains(s)
            || hangulLayout.jungsungMap.keys.contains(s)
            || hangulLayout.jongsungMap.keys.contains(s)
    }

    /// 조합 가능한 문자가 들어온다. 다시 검수할 필요는 없음. 겹자음/겹모음이 있을 수 있기 때문에 previous 를 기준으로 운영.
    /// previous=raw char 조합, preedit=조합중인 한글, commit=조합된 한글
    func 한글조합() -> CommitState {
        logger.debug("- 이전: \(self.previous) 프리에딧: \(String(describing: self.preedit))")
        logger.debug("- 입력: \(self.rawChar)")

        let status = (self.preedit.chosung, self.preedit.jungsung, self.preedit.jongsung)
        switch status {
        case (nil, nil, nil):
            /// "" -> "ㄱ"
            print("시작! 초성을 채움")
            if let 초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
                self.preedit.chosung = 초성(rawValue: 초성코드)
                self.previous.append(self.rawChar)

                return CommitState.composing
            }

            /// "" -> "ㅏ"
            print("시작? 중성을 채움")
            if let 중성코드 = hangulLayout.pickJungsung(by: self.rawChar) {
                self.preedit.jungsung = 중성(rawValue: 중성코드)
                self.previous.append(self.rawChar)

                return CommitState.composing
            }

            /// "" -> "ㄴ"
            print("시작? 종성을 채움")
            if let 종성코드 = hangulLayout.pickJongsung(by: self.rawChar) {
                self.preedit.jongsung = 종성(rawValue: 종성코드)
                self.previous.append(self.rawChar)

                return CommitState.composing
            }
        case (_, nil, nil):
            /// "ㄱ" + "ㅏ" -> "가"
            print("중성이 왔다면!")
            if let 중성코드 = hangulLayout.pickJungsung(by: self.rawChar) {
                self.preedit.jungsung = 중성(rawValue: 중성코드)
                self.previous.removeAll()
                self.previous.append(self.rawChar)

                return CommitState.composing
            }

            /// "ㄱ" -> "ㄲ", "ㄱ" -> "ㄱㄴ", "ㄲ" -> "ㅋ"
            print("초성이 있는데 또 초성이 온 경우, 또는 연타해서 다른 글자를 만들 경우")
            self.previous.append(self.rawChar)
            if let 복합초성코드 = hangulLayout.pickChosung(by: self.previous.joined()) {
                self.preedit.chosung = 초성(rawValue: 복합초성코드)

                return CommitState.composing
            }

            /// "ㄱ" + "ㄱ" -> "ㄲ"
            print("아니면 이제는 새로운 초성이 온 거임 \(self.rawChar)")
            if let 새초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
                self.완성 = self.getComposed()
                self.preedit.chosung = 초성(rawValue: 새초성코드)

                return CommitState.committed
            }
        case (nil, _, nil):
            /// "ㅏ" + "ㅇ" -> "아"
            print("중성이 먼저 오고 초성이 붙는 경우!")
            if let 초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
                self.preedit.chosung = 초성(rawValue: 초성코드)

                return CommitState.composing
            }

            /// "ᅡ" + "ᆻ" -> 채움문자 (완성 낱자를 구할 수 없어서 필요가 없는 조건인데 모아치기를 구성해보면???)
            print("종성이 초성보다 먼저 올수도 있지! 하지만 이건 공세벌만 가능해: \(hangulLayout.can모아치기)")
            /// 공세벌식 자판의 경우 모아치기를 사용할 수 있다!
            if hangulLayout.can모아치기 {
                if let 종성코드 = hangulLayout.pickJongsung(by: self.rawChar) {
                    self.preedit.jongsung = 종성(rawValue: 종성코드)

                    return CommitState.composing
                }
            }

            /// "ㅗ" + "ㅏ" -> "ㅗㅏ"
            print("중성이 있는데 또 중성이 온 경우")
            self.previous.append(self.rawChar)
            if let 복합중성코드 = hangulLayout.pickJungsung(by: self.previous.joined()) {
                self.preedit.jungsung = 중성(rawValue: 복합중성코드)

                return CommitState.composing
            }

            if let 새중성코드 = hangulLayout.pickJungsung(by: self.rawChar) {
                self.완성 = self.getComposed()
                self.preedit.jungsung = 중성(rawValue: 새중성코드)

                return CommitState.committed
            }
        case (nil, nil, _):
            /// "ㄹ" + "ㄱ" -> "ㄺ"
            print("겹밭침을 쓸 수 있다고?")
            self.previous.append(self.rawChar)
            if let 복합종성코드 = hangulLayout.pickJongsung(by: self.previous.joined()) {
                self.preedit.jongsung = 종성(rawValue: 복합종성코드)

                return CommitState.composing
            }

            /// 여기까지 왔다!
            if let 초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
                self.preedit.chosung = 초성(rawValue: 초성코드)

                return CommitState.composing
            }

            /// "ᆻ" + "ᅡ" + "ᄋ" -> "았"
            if let 중성코드 = hangulLayout.pickJungsung(by: self.rawChar) {
                self.preedit.jungsung = 중성(rawValue: 중성코드)

                return CommitState.composing
            }

            /// 이건 새 글자가 된다!
            if let 새종성코드 = hangulLayout.pickJongsung(by: self.rawChar) {
                self.완성 = self.getComposed()
                self.preedit.jongsung = 종성(rawValue: 새종성코드)

                return CommitState.committed
            }
        case (_, _, nil):
            print("받침 없는 글자 이후 다시 초성이?")
            /// "ㄴ" + "ㅗ" + "ㄹ" -> "노ㄹ"
            if let 초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
                print("이전 글자를 commit 해야 함")
                self.완성 = self.getComposed()
                self.clearPreedit()

                self.preedit.chosung = 초성(rawValue: 초성코드)
                self.previous.append(self.rawChar)

                return CommitState.committed
            }

            print("초성과 중성이 있는데 중성이 또 왔다")
            /// "ㅁ" + "ㅗ" + "ㅏ" -> "뫄"
            self.previous.append(self.rawChar)

            if let 복합중성코드 = hangulLayout.pickJungsung(by: self.previous.joined()) {
                self.preedit.jungsung = 중성(rawValue: 복합중성코드)

                return CommitState.composing
            }

            print("종성이 왔다면!")
            /// "ㄱ" + "ㅏ" + "ㅇ" -> "강"
            self.previous.removeAll()
            self.previous.append(self.rawChar)

            if let 종성코드 = hangulLayout.pickJongsung(by: self.previous.joined()) {
                self.preedit.jongsung = 종성(rawValue: 종성코드)

                return CommitState.composing
            }
        case (nil, _, _):
            print("초성이 마지막에 붙는 경우?")
            /// "ᆼ" + "ᅳ" + "ᆨ" -> "윽"
            if let 초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
                self.preedit.chosung = 초성(rawValue: 초성코드)

                return CommitState.composing
            }

            self.완성 = String(UnicodeScalar(그외.채움문자.rawValue)!)
            self.clearPreedit()

            let _ = self.한글조합()
            return CommitState.committed
        case (_, _, _):
            print("초성, 중성, 종성이 있는데?")
            print("겹자음 종성이 있는 경우만 처리")
            /// "ㅂ" + "ㅏ" + "ㄱ" + "ㄱ" -> "밖"
            self.previous.append(self.rawChar)

            if let 복합종성코드 = hangulLayout.pickJongsung(by: self.previous.joined()) {
                self.preedit.jongsung = 종성(rawValue: 복합종성코드)

                return CommitState.composing
            }

            self.완성 = self.getComposed()
            self.clearPreedit()

            let _ = self.한글조합()
            return CommitState.committed
        }

        self.완성 = self.getComposed()
        self.clearPreedit()

        return CommitState.none
    }

    func getComposed() -> String? {
        let hangulComposer = HangulComposer(
            chosungPoint: preedit.chosung,
            jungsungPoint: preedit.jungsung,
            jongsungPoint: preedit.jongsung
        )
        if let composition = hangulComposer?.getSyllable() {
            // logger.debug("조합: \(String(describing: composition)) (\(preedit))")
            return String(composition)
        }

        return nil
    }

    func getCompat(preedit: 글자) -> String? {
        return "호환문자"
    }

    /// 한글이 아닌 문자가 들어오는 경우
    func getConverted() -> String? {
        logger.debug("비한글 조합: \(self.rawChar)")
        if let nonSyllable = self.hangulLayout.pickNonSyllable(by: self.rawChar) {
            return nonSyllable
        }

        return nil
    }

    func clearPreedit() {
        self.preedit.chosung = nil
        self.preedit.jungsung = nil
        self.preedit.jongsung = nil
        self.previous.removeAll()
    }

    func flushCommit() {
        self.rawChar = ""
        self.clearPreedit()
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
