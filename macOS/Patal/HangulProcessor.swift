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

class HangulProcessor {
    internal let logger = CustomLogger(category: "InputTextKey")
    let layoutName: String

    /// OS 에서 제공하는 문자
    var rawChar: String

    /// preedit 에 처리중인 rawChar 배열: 겹낱자나 느슨한 조합을 위한 버퍼
    var composing: [String]
    /// 키 입력 히스토리: 백스페이스 시 정확한 복원을 위해 키 1회 입력 = 1원소
    var keyHistory: [String]
    /// previous 를 한글 처리된 문자
    var preedit: 조합자
    /// 조합 종료된 한글
    var 완성: String?

    var hangulLayout: HangulAutomata

    let managableModifiers = [ModifierCode.NONE.rawValue, ModifierCode.SHIFT.rawValue]

    init(layout: HangulAutomata) {
        layoutName = String(describing: type(of: layout))
        hangulLayout = layout

        logger.debug("입력키 처리 클래스 초기화: \(layoutName)")

        rawChar = ""
        composing = []
        keyHistory = []
        preedit = 조합자()
    }

    deinit {
        logger.debug("입력키 처리 클래스 해제: \(layoutName)")
    }

    /// 조합중인 낱자가 있는지 검사
    func countComposable() -> Int {
        var count = 0
        if preedit.chosung != nil { count += 1 }
        if preedit.jungsung != nil { count += 1 }
        if preedit.jongsung != nil { count += 1 }
        return count
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
            return InputStrategy.directInsert
        }

        return InputStrategy.swapMarked
    }

    /// 처리 가능한 입력인지 검증한다.
    /// - 백스페이스는 별도 처리해야 함
    /// - 모디파이어가 있는 경우는 비한글 처리해야 함
    /// OS 에게 처리 절차를 바로 넘기는 조건
    /// - 백스페이스 + 글자단위 삭제 특성이 활성화 된 경우
    /// - command, option 키와 함께 사용되는 경우
    /// - 한글 레이아웃 자판 맵에 등록되지 않은 키코드 인 경우
    func verifyProcessable(_ s: String, keyCode: Int = 0, modifierCode: Int = 0) -> Bool {
        logger.debug(" => \(s), \(keyCode), \(modifierCode)")

        if !managableModifiers.contains(modifierCode) { return false }

        // 자소단위 삭제(글자단위 삭제가 아닌 경우)인 경우는 composer 로 넘겨야 함(true 반환)
        let composableBackspace =
            !hangulLayout.can글자단위삭제
            && (keyCode == KeyCode.BACKSPACE.rawValue && modifierCode == 0)
        if composableBackspace { return true }

        // 키코드 기반 검증 우선 적용 (라틴 자판 독립적)
        if let hangulChar = KeyCodeMapper.mapKeyCodeToHangulChar(keyCode: keyCode, modifiers: modifierCode) {
            return hangulLayout.chosungMap.keys.contains(hangulChar)
                || hangulLayout.jungsungMap.keys.contains(hangulChar)
                || hangulLayout.jongsungMap.keys.contains(hangulChar)
                || hangulLayout.nonSyllableMap.keys.contains(hangulChar)
        }

        // 키코드 매핑이 없는 경우 기존 문자열 기반 검증 (하위 호환성)
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

    /// 키코드를 한글 입력용 문자로 변환하고 rawChar에 설정
    /// - Parameters:
    ///   - keyCode: 물리적 키코드
    ///   - modifiers: 수정자 키 플래그
    /// - Returns: 변환된 문자 (라틴 자판 독립적)
    func processKeyCodeInput(keyCode: Int, modifiers: Int) -> String? {
        if let hangulChar = KeyCodeMapper.mapKeyCodeToHangulChar(keyCode: keyCode, modifiers: modifiers) {
            rawChar = hangulChar
            logger.debug(
                "키코드 변환: \(KeyCodeMapper.debugKeyInfo(keyCode: keyCode, modifiers: modifiers)) -> '\(hangulChar)'")
            return hangulChar
        }
        return nil
    }

    /// 조합 가능한 문자가 들어온다. 다시 검수할 필요는 없음. 겹자음/겹모음이 있을 수 있기 때문에 previous 를 기준으로 운영.
    /// previous=raw char 조합, preedit=조합중인 한글, commit=조합된 한글
    /// todo: return (previous, preedit, commitState) 튜플로 개선
    func 한글조합() -> CommitState {
        keyHistory.append(rawChar)
        return 한글조합내부()
    }

    /// 내부 조합 로직: 히스토리 관리 없이 순수 조합만 수행 (리플레이용)
    private func 한글조합내부() -> CommitState {
        logger.debug("- 이전: \(composing) 프리에딧: \(String(describing: preedit))")
        logger.debug("- 입력: \(rawChar)")

        let status = (preedit.chosung, preedit.jungsung, preedit.jongsung)
        switch status {
        case (nil, nil, nil):
            /// "" -> "ㄱ"
            print("시작! 초성을 채움")
            if let 초성코드 = hangulLayout.pickChosung(by: rawChar) {
                preedit.chosung = 초성(rawValue: 초성코드)
                composing.append(rawChar)

                return CommitState.composing
            }

            // 느슨한 조합인 경우 중성이 우선
            if hangulLayout.can모아주기 {
                /// "" -> "ㅏ"
                print("시작? 중성을 채움")
                if let 중성코드 = hangulLayout.pickJungsung(by: rawChar) {
                    preedit.jungsung = 중성(rawValue: 중성코드)
                    composing.append(rawChar)

                    return CommitState.composing
                }

                /// "" -> "ㄴ"
                print("시작? 종성을 채움")
                if let 종성코드 = hangulLayout.pickJongsung(by: rawChar) {
                    preedit.jongsung = 종성(rawValue: 종성코드)
                    composing.append(rawChar)

                    return CommitState.composing
                }
            } else {
                print("시작? 종성을 채움")
                if let 종성코드 = hangulLayout.pickJongsung(by: rawChar) {
                    preedit.jongsung = 종성(rawValue: 종성코드)
                    composing.append(rawChar)

                    return CommitState.composing
                }

                print("시작? 중성을 채움")
                if let 중성코드 = hangulLayout.pickJungsung(by: rawChar) {
                    preedit.jungsung = 중성(rawValue: 중성코드)
                    composing.append(rawChar)

                    return CommitState.composing
                }
            }
        case (_, nil, nil):
            /// "ㄱ" + "ㅏ" -> "가"
            print("중성이 왔다면!")
            if let 중성코드 = hangulLayout.pickJungsung(by: rawChar) {
                preedit.jungsung = 중성(rawValue: 중성코드)
                resetComposing(rawChar)

                return CommitState.composing
            }

            /// "ㄱ" + "ㅇ" -> 대체문자
            print("종성이 온다고? \(hangulLayout.can모아주기)")
            if hangulLayout.can모아주기 {
                if let 종성코드 = hangulLayout.pickJongsung(by: rawChar) {
                    preedit.jongsung = 종성(rawValue: 종성코드)
                    resetComposing(rawChar)

                    return CommitState.composing
                }
            }

            /// "ㄱ" -> "ㄲ", "ㄱ" -> "ㄱㄴ", "ㄲ" -> "ㅋ"
            print("초성이 있는데 또 초성이 온 경우, 또는 연타해서 다른 글자를 만들 경우")
            composing.append(rawChar)
            if let 복합초성코드 = hangulLayout.pickChosung(by: composing.joined()) {
                preedit.chosung = 초성(rawValue: 복합초성코드)

                return CommitState.composing
            }

            /// "ㄱ" + "ㄱ" -> "ㄲ"
            print("아니면 이제는 새로운 초성이 온 거임 \(rawChar)")
            if let 새초성코드 = hangulLayout.pickChosung(by: rawChar) {
                완성 = getComposed()
                preedit.chosung = 초성(rawValue: 새초성코드)
                resetComposing(rawChar)

                return CommitState.committed
            }
        case (nil, _, nil):
            /// "ㅏ" + "ㅇ" -> "아"
            print("중성이 먼저 오고 초성이 붙는 경우!")
            if let 초성코드 = hangulLayout.pickChosung(by: rawChar) {
                preedit.chosung = 초성(rawValue: 초성코드)

                return CommitState.composing
            }

            /// "ᅡ" + "ᆻ" -> 대체 문자 (완성 낱자를 구할 수 없어서 필요가 없는 조건인데 느슨한 조합을 구성해보면???)
            print("종성이 먼저 올수도 있지! 이건 중성/종성 나뉜 공세벌만 가능해: \(hangulLayout.can모아주기)")
            /// 공세벌식 자판의 경우 좀 더 느슨한 조합 사용할 수 있다!
            if hangulLayout.can모아주기 {
                if let 종성코드 = hangulLayout.pickJongsung(by: rawChar) {
                    preedit.jongsung = 종성(rawValue: 종성코드)

                    return CommitState.composing
                }
            }

            /// "ㅗ" + "ㅏ" -> "ㅗㅏ"
            print("중성이 있는데 또 중성이 온 경우")
            composing.append(rawChar)
            if let 복합중성코드 = hangulLayout.pickJungsung(by: composing.joined()) {
                preedit.jungsung = 중성(rawValue: 복합중성코드)

                return CommitState.composing
            }

            if let 새중성코드 = hangulLayout.pickJungsung(by: rawChar) {
                완성 = getComposed()
                preedit.jungsung = 중성(rawValue: 새중성코드)

                return CommitState.committed
            }

            /// 종성보다 중성이 먼저 처리되어야 해서 마지막에 둠
            print("새 종성으로 처리하자")
            if let 새종성코드 = hangulLayout.pickJongsung(by: rawChar) {
                완성 = getComposed()
                clearPreedit()

                preedit.jongsung = 종성(rawValue: 새종성코드)

                let _ = 한글조합()
                return CommitState.committed
            }
        case (nil, nil, _):
            /// "ㄹ" + "ㄱ" -> "ㄺ"
            print("겹밭침을 쓸 수 있다고?")
            composing.append(rawChar)
            if let 복합종성코드 = hangulLayout.pickJongsung(by: composing.joined()) {
                preedit.jongsung = 종성(rawValue: 복합종성코드)

                return CommitState.composing
            }

            /// 여기까지 왔다!
            if hangulLayout.can모아주기 {
                if let 초성코드 = hangulLayout.pickChosung(by: rawChar) {
                    preedit.chosung = 초성(rawValue: 초성코드)

                    return CommitState.composing
                }
            } else {
                if let 새초성코드 = hangulLayout.pickChosung(by: rawChar) {
                    완성 = getComposed()
                    clearPreedit()

                    preedit.chosung = 초성(rawValue: 새초성코드)

                    let _ = 한글조합()
                    return CommitState.committed
                }
            }

            /// "ᆻ" + "ᅡ" + "ᄋ" -> "았"
            if hangulLayout.can모아주기 {
                if let 중성코드 = hangulLayout.pickJungsung(by: rawChar) {
                    preedit.jungsung = 중성(rawValue: 중성코드)

                    return CommitState.composing
                }
            }

            /// 이건 새 글자가 된다!
            if let 새종성코드 = hangulLayout.pickJongsung(by: rawChar) {
                완성 = getComposed()
                preedit.jongsung = 종성(rawValue: 새종성코드)

                return CommitState.committed
            }
        case (_, nil, _):
            print("중성아 느슨하게 조합 하자!")
            if let 중성코드 = hangulLayout.pickJungsung(by: rawChar) {
                preedit.jungsung = 중성(rawValue: 중성코드)

                return CommitState.composing
            }
        case (_, _, nil):
            print("받침 없는 글자 이후 다시 초성이?")
            /// "ㄴ" + "ㅗ" + "ㄹ" -> "노ㄹ"
            if let 초성코드 = hangulLayout.pickChosung(by: rawChar) {
                print("이전 글자를 commit 해야 함")
                완성 = getComposed()
                clearPreedit()

                preedit.chosung = 초성(rawValue: 초성코드)
                composing.append(rawChar)

                return CommitState.committed
            }

            print("초성과 중성이 있는데 중성이 또 왔다")
            /// "ㅁ" + "ㅗ" + "ㅏ" -> "뫄"
            // 백스페이스로 종성을 지우고 다시 종성을 조합하기 위해 previous 를 검사해야 함
            if composing.count > 0 {
                composing.append(rawChar)

                if let 복합중성코드 = hangulLayout.pickJungsung(by: composing.joined()) {
                    preedit.jungsung = 중성(rawValue: 복합중성코드)

                    return CommitState.composing
                }
            }

            print("종성이 왔다면!")
            /// "ㄱ" + "ㅏ" + "ㅇ" -> "강"
            resetComposing(rawChar)

            if let 종성코드 = hangulLayout.pickJongsung(by: composing.joined()) {
                preedit.jongsung = 종성(rawValue: 종성코드)

                return CommitState.composing
            }
        case (nil, _, _):
            print("초성이 마지막에 붙는 경우?")
            /// "ᆼ" + "ᅳ" + "ᆨ" -> "윽"
            if let 초성코드 = hangulLayout.pickChosung(by: rawChar) {
                preedit.chosung = 초성(rawValue: 초성코드)

                return CommitState.composing
            }

            완성 = String(UnicodeScalar(그외.대체문자.rawValue)!)
            clearPreedit()

            let _ = 한글조합()
            return CommitState.committed
        case (_, _, _):
            print("초성, 중성, 종성이 있는데?")
            print("겹자음 종성이 있는 경우만 처리")
            /// "ㅂ" + "ㅏ" + "ㄱ" + "ㄱ" -> "밖"
            composing.append(rawChar)

            if let 복합종성코드 = hangulLayout.pickJongsung(by: composing.joined()) {
                preedit.jongsung = 종성(rawValue: 복합종성코드)

                return CommitState.composing
            }

            완성 = getComposed()
            clearPreedit()

            let _ = 한글조합()
            return CommitState.committed
        }

        완성 = getComposed()
        clearPreedit()

        return CommitState.none
    }

    /// 준비된 조합자를 한글 글자로 변환
    func getComposed() -> String? {
        if let hangulComposer = HangulComposer(
            chosungPoint: preedit.chosung,
            jungsungPoint: preedit.jungsung,
            jongsungPoint: preedit.jongsung
        ) {
            if let char = hangulComposer.getSyllable() {
                return String(char)
            }
        }
        // 현대한글 조합을 못하면 옛한글 시도
        if let char = getComposedAlternative(preedit: preedit) {
            return String(char)
        }

        return nil
    }

    /// 현대한글로 전환하지 못한 경우 NFD 로 제공
    func getComposedAlternative(preedit: 조합자) -> Character? {
        var unicodeScalars = String.UnicodeScalarView()

        if let codePoint = preedit.chosung {
            let scala = UnicodeScalar(codePoint.rawValue)!
            unicodeScalars.append(UnicodeScalar(scala))
        }
        if let codePoint = preedit.jungsung {
            let scala = UnicodeScalar(codePoint.rawValue)!
            unicodeScalars.append(UnicodeScalar(scala))
        }
        if let codePoint = preedit.jongsung {
            let scala = UnicodeScalar(codePoint.rawValue)!
            unicodeScalars.append(UnicodeScalar(scala))
        }

        if unicodeScalars.count > 0 {
            return Character(UnicodeScalarType(unicodeScalars))
        }

        return nil
    }

    /// 한글이 아닌 문자가 들어오는 경우
    func getConverted() -> String? {
        if let nonSyllable = hangulLayout.pickNonSyllable(by: rawChar) {
            return nonSyllable
        }

        return nil
    }

    /// 백스페이스가 들어오면 키 히스토리에서 마지막 입력을 제거하고 재조합
    func applyBackspace() -> Int {
        guard !keyHistory.isEmpty else {
            logger.debug("백스페이스: 히스토리 비어있음")
            return 0
        }

        keyHistory.removeLast()
        logger.debug("백스페이스: 히스토리에서 제거 후 \(keyHistory)")

        if keyHistory.isEmpty {
            resetPreeditState()
            logger.debug("백스페이스 처리 후: 빈 상태")
            return 0
        }

        recomputeFromHistory()
        logger.debug("백스페이스 처리 후: \(String(describing: preedit)) \(composing)")

        return countComposable()
    }

    func resetComposing(_ s: String) {
        composing.removeAll()
        composing.append(s)
    }

    func clearPreedit() {
        preedit.chosung = nil
        preedit.jungsung = nil
        preedit.jongsung = nil
        composing.removeAll()
        keyHistory.removeAll()
    }

    /// preedit 상태만 초기화 (keyHistory 유지)
    private func resetPreeditState() {
        preedit.chosung = nil
        preedit.jungsung = nil
        preedit.jongsung = nil
        composing.removeAll()
        완성 = nil
    }

    /// 키 히스토리를 기반으로 preedit 상태를 재계산
    /// 백스페이스 후 정확한 중간 상태 복원에 사용
    func recomputeFromHistory() {
        let savedHistory = keyHistory
        resetPreeditState()
        keyHistory.removeAll()

        for key in savedHistory {
            rawChar = key
            let state = 한글조합내부()
            if state == .committed {
                완성 = nil
            }
        }
        keyHistory = savedHistory
    }

    func clearBuffers() {
        rawChar = ""
        완성 = nil
    }

    func composeCommitToUpdate() -> String? {
        if let syllable = getComposed() {
            logger.debug("조합이 가능함: \(String(describing: syllable))")
            return syllable
        }
        /// 조합이 불가능한 경우 대체 문자를 제공
        if composing.count > 0 {
            logger.debug("조합이 불가능함: \(String(describing: composing))")
            return String(UnicodeScalar(그외.대체문자.rawValue)!)
        }
        return nil
    }

    /// 버퍼에 있는 커밋이나 조합 중인 글자를 내보내기
    func flushCommit() -> [String] {
        var buffers: [String] = []
        // 남은 문자가 있는 경우 내보내자
        if let commit = 완성 {
            // 이 경우는 거의 없을 거 같은데...
            logger.debug("남은 완성 글자 내보내기: \(String(describing: commit))")
            buffers.append(commit)
        }
        if let preedit = getComposed() {
            logger.debug("조합 중인 글자 내보내기: \(String(describing: preedit))")
            buffers.append(preedit)
        }
        if let nonSyllable = getConverted() {
            logger.debug("조합 불가한 글자 내보내기: \(String(describing: nonSyllable))")
            buffers.append(nonSyllable)
        }

        clearPreedit()
        clearBuffers()

        return buffers
    }
}
