//
//  InputKey.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation
import InputMethodKit

/// 조합 처리 후 결과를 담고 있음; 처리 과정의 상태는 preedit 의 상태를 판단하면 됨
enum ComposeState {
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

    let hangulLayout = Han3ShinPcsLayout()

    init(layout: Layout) {
        logger.debug("입력키 처리 클래스 초기화: \(layout)")
        self.rawChar = ""
        self.previous = []
        self.preedit = 글자()
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

    /// 조합 가능한 입력인지 검증한다.
    func verifyCombosable(_ s: String) -> Bool {
        return hangulLayout.chosungMap.keys.contains(s)
            || hangulLayout.jungsungMap.keys.contains(s)
            || hangulLayout.jongsungMap.keys.contains(s)
    }

    /// 조합 가능한 문자가 들어온다. 다시 검수할 필요는 없음. 겹자음/겹모음이 있을 수 있기 때문에 previous 를 기준으로 운영.
    /// previous=raw char 조합, preedit=조합중인 한글, commit=조합된 한글
    func composeBuffer() -> ComposeState {
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

                return ComposeState.composing
            }

            /// "" -> "ㅏ"
            print("시작? 중성을 채움")
            if let 중성코드 = hangulLayout.pickJungsung(by: self.rawChar) {
                self.preedit.jungsung = 중성(rawValue: 중성코드)
                self.previous.append(self.rawChar)

                return ComposeState.composing
            }

            /// "" -> "ㄴ"
            print("시작? 종성을 채움")
            if let 종성코드 = hangulLayout.pickJongsung(by: self.rawChar) {
                self.preedit.jongsung = 종성(rawValue: 종성코드)
                self.previous.append(self.rawChar)

                return ComposeState.composing
            }
        case (_, nil, nil):
            /// "ㄱ" + "ㅏ" -> "가"
            print("중성이 왔다면!")
            if let 중성코드 = hangulLayout.pickJungsung(by: self.rawChar) {
                self.preedit.jungsung = 중성(rawValue: 중성코드)
                self.previous.removeAll()
                self.previous.append(self.rawChar)

                return ComposeState.composing
            }

            /// "ㄱ" -> "ㄲ", "ㄱ" -> "ㄱㄴ", "ㄲ" -> "ㅋ"
            print("초성이 있는데 또 초성이 온 경우, 또는 연타해서 다른 글자를 만들 경우")
            self.previous.append(self.rawChar)
            if let 복합초성코드 = hangulLayout.pickChosung(by: self.previous.joined()) {
                self.preedit.chosung = 초성(rawValue: 복합초성코드)

                return ComposeState.composing
            }

            /// "ㄱ" + "ㄱ" -> "ㄲ"
            print("아니면 이제는 새로운 초성이 온 거임 \(self.rawChar)")
            if let 초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
                self.preedit.chosung = 초성(rawValue: 초성코드)
                self.완성 = self.getComposed()

                return ComposeState.committed
            }
        case (nil, _, nil):
            /// "ㅏ" + "ㅇ" -> "아"
            print("중성이 먼저 오고 초성이 붙는 경우!")
            if let 초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
                self.preedit.chosung = 초성(rawValue: 초성코드)

                return ComposeState.composing
            }

            /// "ㅗ" + "ㅏ" -> "ㅗㅏ"
            print("중성이 있는데 또 중성이 온 경우")
            self.previous.append(self.rawChar)
            if let 복합중성코드 = hangulLayout.pickJungsung(by: self.previous.joined()) {
                self.preedit.jungsung = 중성(rawValue: 복합중성코드)

                return ComposeState.composing
            }

            if let 중성코드 = hangulLayout.pickJungsung(by: self.rawChar) {
                self.preedit.jungsung = 중성(rawValue: 중성코드)
                self.완성 = self.getComposed()

                return ComposeState.committed
            }
        case (nil, nil, _):
            /// "ㄹ" + "ㄱ" -> "ㄺ"
            print("겹밭침을 쓸 수 있다고?")
            self.previous.append(self.rawChar)
            if let 복합종성코드 = hangulLayout.pickJongsung(by: self.previous.joined()) {
                self.preedit.jongsung = 종성(rawValue: 복합종성코드)

                return ComposeState.composing
            }

            if let 종성코드 = hangulLayout.pickJongsung(by: self.rawChar) {
                self.preedit.jongsung = 종성(rawValue: 종성코드)
                self.완성 = self.getComposed()

                return ComposeState.committed
            }
        case (_, _, nil):
            print("받침 없는 글자 이후 다시 초성이?")
            /// "ㄴ" + "ㅗ" + "ㄹ" -> "노ㄹ"
            if let 초성코드 = hangulLayout.pickChosung(by: self.rawChar) {
                print("이전 글자를 commit 해야 함")
                self.완성 = self.getComposed()
                self.commit()

                self.preedit.chosung = 초성(rawValue: 초성코드)
                self.previous.append(self.rawChar)

                return ComposeState.committed
            }

            print("초성과 중성이 있는데 중성이 또 왔다")
            /// "ㅁ" + "ㅗ" + "ㅏ" -> "뫄"
            self.previous.append(self.rawChar)

            if let 복합중성코드 = hangulLayout.pickJungsung(by: self.previous.joined()) {
                self.preedit.jungsung = 중성(rawValue: 복합중성코드)

                return ComposeState.composing
            }

            print("종성이 왔다면!")
            /// "ㄱ" + "ㅏ" + "ㅇ" -> "강"
            self.previous.removeAll()
            self.previous.append(self.rawChar)

            if let 종성코드 = hangulLayout.pickJongsung(by: self.previous.joined()) {
                self.preedit.jongsung = 종성(rawValue: 종성코드)

                return ComposeState.composing
            }
        case (_, _, _):
            print("초성, 중성, 종성이 있는데?")
            print("겹자음 종성이 있는 경우만 처리")
            /// "ㅂ" + "ㅏ" + "ㄱ" + "ㄱ" -> "밖"
            self.previous.append(self.rawChar)

            if let 복합종성코드 = hangulLayout.pickJongsung(by: self.previous.joined()) {
                self.preedit.jongsung = 종성(rawValue: 복합종성코드)

                return ComposeState.committed
            }

            self.완성 = self.getComposed()
            self.commit()

            let _ = self.composeBuffer()
            return ComposeState.committed
        }

        print("preedit: \(String(describing: self.preedit))")
        self.완성 = self.getComposed()
        print("commit: \(String(describing: self.완성))")
        self.commit()

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
        self.preedit.chosung = nil
        self.preedit.jungsung = nil
        self.preedit.jongsung = nil
        self.previous.removeAll()
    }

    func flush() {
        self.rawChar = ""
        self.commit()
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
