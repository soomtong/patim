//
//  CompositionStateMachine.swift
//  Patal
//
//  순수 함수형 상태 기계 - 상태 전이만 담당
//  외부 의존성 없음, 완전히 테스트 가능
//

import Foundation

/// 상태 전이 결과 타입
enum ResultType: Equatable {
    /// 조합 진행 중
    case composing
    /// 글자 확정 + 새 조합 시작
    case committed
    /// 조합 종료 (빈 상태)
    case cleared
    /// 변화 없음
    case unchanged
}

/// 상태 전이 결과
struct TransitionResult: Equatable {
    /// 새로운 조합 상태
    let newState: CompositionState
    /// 확정된 글자 (있는 경우)
    let committedChar: String?
    /// 결과 타입
    let resultType: ResultType

    /// 조합 중 결과 생성
    static func composing(_ state: CompositionState) -> TransitionResult {
        TransitionResult(newState: state, committedChar: nil, resultType: .composing)
    }

    /// 확정 결과 생성
    static func committed(_ state: CompositionState, char: String?) -> TransitionResult {
        TransitionResult(newState: state, committedChar: char, resultType: .committed)
    }

    /// 클리어 결과 생성
    static func cleared(char: String? = nil) -> TransitionResult {
        TransitionResult(newState: .empty, committedChar: char, resultType: .cleared)
    }

    /// 변화 없음 결과 생성
    static func unchanged(_ state: CompositionState) -> TransitionResult {
        TransitionResult(newState: state, committedChar: nil, resultType: .unchanged)
    }
}

/// 순수 함수형 상태 기계
/// 레이아웃과 규칙을 주입받아 상태 전이 수행
struct CompositionStateMachine {
    private let layout: HangulAutomata
    private let rule: SyllableRule

    init(layout: HangulAutomata, syllableRule: SyllableRule = DefaultSyllableRule()) {
        self.layout = layout
        self.rule = syllableRule
    }

    // MARK: - 메인 전이 함수

    /// 이벤트를 받아 상태 전이 수행
    func transition(from state: CompositionState, with event: InputEvent) -> TransitionResult {
        switch event {
        case .jamo(let input):
            return handleJamoInput(state: state, input: input)
        case .backspace:
            return handleBackspace(state: state)
        case .commit:
            return handleCommit(state: state)
        case .cancel:
            return handleCancel(state: state)
        }
    }

    // MARK: - 이벤트 핸들러

    private func handleJamoInput(state: CompositionState, input: JamoInput) -> TransitionResult {
        let status = (state.chosung, state.jungsung, state.jongsung)

        switch status {
        case (nil, nil, nil):
            return handleEmptyState(input: input)

        case (.some, nil, nil):
            return handleInitialConsonant(state: state, input: input)

        case (nil, .some, nil):
            return handleVowelOnly(state: state, input: input)

        case (nil, nil, .some):
            return handleFinalOnly(state: state, input: input)

        case (.some, nil, .some):
            return handleConsonantFinal(state: state, input: input)

        case (.some, .some, nil):
            return handleConsonantVowel(state: state, input: input)

        case (nil, .some, .some):
            return handleVowelFinal(state: state, input: input)

        case (.some, .some, .some):
            return handleComplete(state: state, input: input)
        }
    }

    private func handleBackspace(state: CompositionState) -> TransitionResult {
        let status = (state.chosung, state.jungsung, state.jongsung)

        switch status {
        case (nil, nil, nil):
            // 빈 상태 - 변화 없음
            return .unchanged(state)

        case (.some, nil, nil):
            // 초성만 - 초성 제거
            return .cleared()

        case (nil, .some, nil):
            // 중성만 (모아주기) - 중성 제거
            return .cleared()

        case (nil, nil, .some):
            // 종성만 (모아주기) - 종성 제거
            return .cleared()

        case (let cho, .some, nil):
            // 초성+중성 - 중성 제거, 초성만 남김
            if let chosung = cho {
                let recovered = layout.getChosungRawString(by: chosung)
                let newState = CompositionState(
                    chosung: chosung,
                    jungsung: nil,
                    jongsung: nil,
                    composingBuffer: [recovered]
                )
                return .composing(newState)
            }
            return .cleared()

        case (.some(let cho), nil, .some):
            // 초성+종성 (모아주기) - 종성 제거, 초성만 남김
            let recovered = layout.getChosungRawString(by: cho)
            let newState = CompositionState(
                chosung: cho,
                jungsung: nil,
                jongsung: nil,
                composingBuffer: [recovered]
            )
            return .composing(newState)

        case (nil, .some(let jung), .some):
            // 중성+종성 (모아주기) - 종성 제거, 중성만 남김
            let recovered = layout.getJungsungRawString(by: jung)
            let newState = CompositionState(
                chosung: nil,
                jungsung: jung,
                jongsung: nil,
                composingBuffer: [recovered]
            )
            return .composing(newState)

        case (let cho, let jung, .some):
            // 초성+중성+종성 - 종성 제거, 초성+중성 남김
            if let jungsung = jung {
                let recovered = layout.getJungsungRawString(by: jungsung)
                let newState = CompositionState(
                    chosung: cho,
                    jungsung: jungsung,
                    jongsung: nil,
                    composingBuffer: [recovered]
                )
                return .composing(newState)
            }
            return .unchanged(state)
        }
    }

    private func handleCommit(state: CompositionState) -> TransitionResult {
        guard state.isComposing else {
            return .unchanged(state)
        }

        let composed = composeSyllable(state: state)
        return .cleared(char: composed)
    }

    private func handleCancel(state: CompositionState) -> TransitionResult {
        // cancel은 commit과 동일하게 처리
        return handleCommit(state: state)
    }

    // MARK: - 상태별 자모 처리

    /// 빈 상태에서 자모 입력
    private func handleEmptyState(input: JamoInput) -> TransitionResult {
        switch input.jamoType {
        case .chosung(let cho):
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .jungsung(let jung):
            // 3-벌식: 중성만 입력해도 조합 상태 (나중에 초성이 올 수 있음)
            let newState = CompositionState(
                jungsung: jung,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .jongsung(let jong):
            // 한글 자음(종성) 단독 입력은 항상 허용
            // 모아주기와 관계없이 조합 상태로 전환
            let newState = CompositionState(
                jongsung: jong,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .chosungOrJongsung(let cho, _):
            // 빈 상태에서는 초성으로 처리
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .chosungOrJungsung(let cho, _):
            // 빈 상태에서는 초성으로 처리
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .jungsungOrJongsung(let jung, let jong, let hasUppercase):
            // 모아주기 활성화: 중성 우선 (유연한 조합 모드)
            // 모아주기 비활성화 + 대문자 대안 있음: 종성 우선 (자음 단독 입력)
            // 모아주기 비활성화 + 대문자 대안 없음: 중성 우선
            if layout.can모아주기 || !hasUppercase {
                let newState = CompositionState(
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .composing(newState)
            } else {
                let newState = CompositionState(
                    jongsung: jong,
                    composingBuffer: [input.rawChar]
                )
                return .composing(newState)
            }
        }
    }

    /// 초성만 있는 상태에서 자모 입력
    private func handleInitialConsonant(state: CompositionState, input: JamoInput) -> TransitionResult {
        switch input.jamoType {
        case .jungsung(let jung):
            // 중성 추가 → 초성+중성
            let newState = CompositionState(
                chosung: state.chosung,
                jungsung: jung,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .jongsung(let jong):
            // 종성 추가 (모아주기)
            if layout.can모아주기 {
                let newState = CompositionState(
                    chosung: state.chosung,
                    jongsung: jong,
                    composingBuffer: [input.rawChar]
                )
                return .composing(newState)
            }
            // 모아주기 아니면 이전 초성 확정 + 새 글자 시작
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                jongsung: jong,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .chosung(let cho):
            // 겹초성 시도
            var newBuffer = state.composingBuffer
            newBuffer.append(input.rawChar)

            if let combined = layout.pickChosung(by: newBuffer.joined()) {
                let newState = CompositionState(
                    chosung: 초성(rawValue: combined),
                    composingBuffer: newBuffer
                )
                return .composing(newState)
            }

            // 겹초성 아니면 이전 초성 확정 + 새 초성 시작
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .chosungOrJongsung(let cho, let jong):
            // 모아주기면 종성으로
            if layout.can모아주기 {
                let newState = CompositionState(
                    chosung: state.chosung,
                    jongsung: jong,
                    composingBuffer: [input.rawChar]
                )
                return .composing(newState)
            }
            // 아니면 새 초성
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .jungsungOrJongsung(let jung, _, _):
            // 초성 뒤에서는 중성으로 처리 (모음 추가)
            let newState = CompositionState(
                chosung: state.chosung,
                jungsung: jung,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .chosungOrJungsung(_, let jung):
            // 초성 뒤에서는 중성으로 처리 (모음 추가)
            let newState = CompositionState(
                chosung: state.chosung,
                jungsung: jung,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)
        }
    }

    /// 중성만 있는 상태 (모아주기)
    private func handleVowelOnly(state: CompositionState, input: JamoInput) -> TransitionResult {
        switch input.jamoType {
        case .chosung(let cho):
            // 초성 추가
            let newState = CompositionState(
                chosung: cho,
                jungsung: state.jungsung,
                composingBuffer: state.composingBuffer
            )
            return .composing(newState)

        case .jungsung(let jung):
            // 겹중성 시도
            var newBuffer = state.composingBuffer
            newBuffer.append(input.rawChar)

            if let combined = layout.pickJungsung(by: newBuffer.joined()) {
                let newState = CompositionState(
                    jungsung: 중성(rawValue: combined),
                    composingBuffer: newBuffer
                )
                return .composing(newState)
            }

            // 겹중성 아니면 이전 중성 확정 + 새 중성 시작
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                jungsung: jung,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .jongsung(let jong):
            if layout.can모아주기 {
                let newState = CompositionState(
                    jungsung: state.jungsung,
                    jongsung: jong,
                    composingBuffer: [input.rawChar]
                )
                return .composing(newState)
            }
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                jongsung: jong,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .chosungOrJongsung(let cho, _):
            // 초성으로 처리
            let newState = CompositionState(
                chosung: cho,
                jungsung: state.jungsung,
                composingBuffer: state.composingBuffer
            )
            return .composing(newState)

        case .chosungOrJungsung(let cho, _):
            // 초성으로 처리
            let newState = CompositionState(
                chosung: cho,
                jungsung: state.jungsung,
                composingBuffer: state.composingBuffer
            )
            return .composing(newState)

        case .jungsungOrJongsung(_, let jong, _):
            // jungsungOrJongsung 키는 종성으로 처리 (겹중성 원하면 순수 중성 키 사용)
            // 3-벌식: 중성+종성 조합
            let newState = CompositionState(
                jungsung: state.jungsung,
                jongsung: jong,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)
        }
    }

    /// 종성만 있는 상태 (모아주기)
    private func handleFinalOnly(state: CompositionState, input: JamoInput) -> TransitionResult {
        switch input.jamoType {
        case .chosung(let cho):
            if layout.can모아주기 {
                let newState = CompositionState(
                    chosung: cho,
                    jongsung: state.jongsung,
                    composingBuffer: state.composingBuffer
                )
                return .composing(newState)
            }
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .jungsung(let jung):
            if layout.can모아주기 {
                let newState = CompositionState(
                    jungsung: jung,
                    jongsung: state.jongsung,
                    composingBuffer: [input.rawChar]
                )
                return .composing(newState)
            }
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                jungsung: jung,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .jongsung(let jong):
            // 겹종성 시도
            var newBuffer = state.composingBuffer
            newBuffer.append(input.rawChar)

            if let combined = layout.pickJongsung(by: newBuffer.joined()) {
                let newState = CompositionState(
                    jongsung: 종성(rawValue: combined),
                    composingBuffer: newBuffer
                )
                return .composing(newState)
            }

            // 겹종성 아니면 새 종성으로
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                jongsung: jong,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .chosungOrJongsung(let cho, _):
            if layout.can모아주기 {
                let newState = CompositionState(
                    chosung: cho,
                    jongsung: state.jongsung,
                    composingBuffer: state.composingBuffer
                )
                return .composing(newState)
            }
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .jungsungOrJongsung(let jung, let jong, let hasUppercase):
            // 먼저 겹종성 시도
            var newBuffer = state.composingBuffer
            newBuffer.append(input.rawChar)

            if let combined = layout.pickJongsung(by: newBuffer.joined()) {
                let newState = CompositionState(
                    jongsung: 종성(rawValue: combined),
                    composingBuffer: newBuffer
                )
                return .composing(newState)
            }

            // 겹종성 불가, 모아주기: 중성으로 처리 (중성+종성 가능)
            if layout.can모아주기 {
                let newState = CompositionState(
                    jungsung: jung,
                    jongsung: state.jongsung,
                    composingBuffer: [input.rawChar]
                )
                return .composing(newState)
            }

            // 모아주기 아님: hasUppercase에 따라 결정
            let committed = composeSyllable(state: state)
            if hasUppercase {
                // 대문자로 중성 입력 가능 → 종성으로 처리
                let newState = CompositionState(
                    jongsung: jong,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            } else {
                // 중성 입력 유일 방법 → 중성으로 처리
                let newState = CompositionState(
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }

        case .chosungOrJungsung(let cho, _):
            // 종성만 있는 상태에서는 초성으로 처리
            if layout.can모아주기 {
                let newState = CompositionState(
                    chosung: cho,
                    jongsung: state.jongsung,
                    composingBuffer: state.composingBuffer
                )
                return .composing(newState)
            }
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)
        }
    }

    /// 초성+종성 상태 (모아주기)
    private func handleConsonantFinal(state: CompositionState, input: JamoInput) -> TransitionResult {
        switch input.jamoType {
        case .jungsung(let jung):
            // 중성 추가 → 완성
            let newState = CompositionState(
                chosung: state.chosung,
                jungsung: jung,
                jongsung: state.jongsung,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .jungsungOrJongsung(let jung, _, _):
            // 초성+종성 상태에서는 중성으로 처리 → 완성
            let newState = CompositionState(
                chosung: state.chosung,
                jungsung: jung,
                jongsung: state.jongsung,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .chosungOrJungsung(_, let jung):
            // 초성+종성 상태에서는 중성으로 처리 → 완성
            let newState = CompositionState(
                chosung: state.chosung,
                jungsung: jung,
                jongsung: state.jongsung,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .chosung, .jongsung, .chosungOrJongsung:
            // 다른 자모는 확정 후 새로 시작
            let committed = composeSyllable(state: state)
            return handleEmptyState(input: input).with(committed: committed)
        }
    }

    /// 초성+중성 상태
    private func handleConsonantVowel(state: CompositionState, input: JamoInput) -> TransitionResult {
        switch input.jamoType {
        case .chosung(let cho):
            // 새 초성 → 이전 글자 확정
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .jungsung(let jung):
            // 겹중성 시도
            var newBuffer = state.composingBuffer
            newBuffer.append(input.rawChar)

            if let combined = layout.pickJungsung(by: newBuffer.joined()) {
                let newState = CompositionState(
                    chosung: state.chosung,
                    jungsung: 중성(rawValue: combined),
                    composingBuffer: newBuffer
                )
                return .composing(newState)
            }

            // 겹중성 아니면 이전 글자 확정 + 중성만 시작
            let committed = composeSyllable(state: state)
            if layout.can모아주기 {
                let newState = CompositionState(
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }
            let char = String(Character(UnicodeScalar(jung.rawValue)!))
            return .cleared(char: (committed ?? "") + char)

        case .jongsung(let jong):
            // 종성 추가 - 새 종성 시작이므로 버퍼 리셋
            let newState = CompositionState(
                chosung: state.chosung,
                jungsung: state.jungsung,
                jongsung: jong,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .chosungOrJongsung(_, let jong):
            // 3-벌식: 종성으로 처리 - 새 종성 시작이므로 버퍼 리셋
            let newState = CompositionState(
                chosung: state.chosung,
                jungsung: state.jungsung,
                jongsung: jong,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .jungsungOrJongsung(_, let jong, _):
            // 먼저 겹중성 시도 (겹모음이 가능한 경우 우선)
            var newBuffer = state.composingBuffer
            newBuffer.append(input.rawChar)

            if let combined = layout.pickJungsung(by: newBuffer.joined()) {
                let newState = CompositionState(
                    chosung: state.chosung,
                    jungsung: 중성(rawValue: combined),
                    composingBuffer: newBuffer
                )
                return .composing(newState)
            }

            // 겹중성 불가 → 초성+중성 상태에서는 종성으로 처리하여 음절 완성
            let newState = CompositionState(
                chosung: state.chosung,
                jungsung: state.jungsung,
                jongsung: jong,
                composingBuffer: [input.rawChar]
            )
            return .composing(newState)

        case .chosungOrJungsung(let cho, _):
            // 초성+중성 상태에서는 새 초성으로 → 이전 글자 확정
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)
        }
    }

    /// 중성+종성 상태 (모아주기)
    private func handleVowelFinal(state: CompositionState, input: JamoInput) -> TransitionResult {
        switch input.jamoType {
        case .chosung(let cho):
            // 초성 추가 → 완성
            let newState = CompositionState(
                chosung: cho,
                jungsung: state.jungsung,
                jongsung: state.jongsung,
                composingBuffer: state.composingBuffer
            )
            return .composing(newState)

        case .chosungOrJongsung(let cho, _):
            // 초성으로 처리 → 완성
            let newState = CompositionState(
                chosung: cho,
                jungsung: state.jungsung,
                jongsung: state.jongsung,
                composingBuffer: state.composingBuffer
            )
            return .composing(newState)

        case .chosungOrJungsung(let cho, _):
            // 초성으로 처리 → 완성
            let newState = CompositionState(
                chosung: cho,
                jungsung: state.jungsung,
                jongsung: state.jongsung,
                composingBuffer: state.composingBuffer
            )
            return .composing(newState)

        case .jungsung, .jongsung, .jungsungOrJongsung:
            let committed = composeSyllable(state: state)
            return handleEmptyState(input: input).with(committed: committed)
        }
    }

    /// 초성+중성+종성 완성 상태
    private func handleComplete(state: CompositionState, input: JamoInput) -> TransitionResult {
        switch input.jamoType {
        case .jongsung(let jong):
            // 겹종성 시도
            var newBuffer = state.composingBuffer
            newBuffer.append(input.rawChar)

            if let combined = layout.pickJongsung(by: newBuffer.joined()) {
                let newState = CompositionState(
                    chosung: state.chosung,
                    jungsung: state.jungsung,
                    jongsung: 종성(rawValue: combined),
                    composingBuffer: newBuffer
                )
                return .composing(newState)
            }

            // 겹종성 아니면 이전 글자 확정 + 새 글자 시작
            let committed = composeSyllable(state: state)
            if layout.can모아주기 {
                let newState = CompositionState(
                    jongsung: jong,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }
            return .committed(.empty, char: committed)

        case .chosung(let cho):
            // 새 초성 → 이전 글자 확정
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .jungsung(let jung):
            // 새 중성 → 종성을 초성으로 분리 시도
            if let (firstJong, secondCho) = rule.canSplitFinal(state.jongsung!) {
                // 겹받침 분리: ㄳ → ㄱ (종성) + ㅅ (초성)
                let prevState = CompositionState(
                    chosung: state.chosung,
                    jungsung: state.jungsung,
                    jongsung: firstJong
                )
                let committed = composeSyllable(state: prevState)
                let newState = CompositionState(
                    chosung: secondCho,
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }

            // 단일 종성을 초성으로 변환
            if let newCho = rule.jongsungToChosung(state.jongsung!) {
                let prevState = CompositionState(
                    chosung: state.chosung,
                    jungsung: state.jungsung,
                    jongsung: nil
                )
                let committed = composeSyllable(state: prevState)
                let newState = CompositionState(
                    chosung: newCho,
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }

            // 변환 불가 → 전체 확정
            let committed = composeSyllable(state: state)
            if layout.can모아주기 {
                let newState = CompositionState(
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }
            let char = String(Character(UnicodeScalar(jung.rawValue)!))
            return .cleared(char: (committed ?? "") + char)

        case .chosungOrJongsung(let cho, _):
            // 겹종성 시도
            var newBuffer = state.composingBuffer
            newBuffer.append(input.rawChar)

            if let combined = layout.pickJongsung(by: newBuffer.joined()) {
                let newState = CompositionState(
                    chosung: state.chosung,
                    jungsung: state.jungsung,
                    jongsung: 종성(rawValue: combined),
                    composingBuffer: newBuffer
                )
                return .composing(newState)
            }

            // 아니면 새 초성으로
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .jungsungOrJongsung(let jung, _, _):
            // 먼저 겹종성 시도
            var newBuffer = state.composingBuffer
            newBuffer.append(input.rawChar)

            if let combined = layout.pickJongsung(by: newBuffer.joined()) {
                let newState = CompositionState(
                    chosung: state.chosung,
                    jungsung: state.jungsung,
                    jongsung: 종성(rawValue: combined),
                    composingBuffer: newBuffer
                )
                return .composing(newState)
            }

            // 겹종성 불가 → 중성으로 처리 (종성 분리 시도)
            if let (firstJong, secondCho) = rule.canSplitFinal(state.jongsung!) {
                // 겹받침 분리: ㄳ → ㄱ (종성) + ㅅ (초성)
                let prevState = CompositionState(
                    chosung: state.chosung,
                    jungsung: state.jungsung,
                    jongsung: firstJong
                )
                let committed = composeSyllable(state: prevState)
                let newState = CompositionState(
                    chosung: secondCho,
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }

            // 단일 종성을 초성으로 변환
            if let newCho = rule.jongsungToChosung(state.jongsung!) {
                let prevState = CompositionState(
                    chosung: state.chosung,
                    jungsung: state.jungsung,
                    jongsung: nil
                )
                let committed = composeSyllable(state: prevState)
                let newState = CompositionState(
                    chosung: newCho,
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }

            // 변환 불가 → 전체 확정 + 새 중성 시작
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                jungsung: jung,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)

        case .chosungOrJungsung(let cho, let jung):
            // 완성 상태에서 초성/중성 공유 키 → 중성으로 처리 (종성 분리 시도)
            if let (firstJong, secondCho) = rule.canSplitFinal(state.jongsung!) {
                // 겹받침 분리: ㄳ → ㄱ (종성) + ㅅ (초성)
                let prevState = CompositionState(
                    chosung: state.chosung,
                    jungsung: state.jungsung,
                    jongsung: firstJong
                )
                let committed = composeSyllable(state: prevState)
                let newState = CompositionState(
                    chosung: secondCho,
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }

            // 단일 종성을 초성으로 변환
            if let newCho = rule.jongsungToChosung(state.jongsung!) {
                let prevState = CompositionState(
                    chosung: state.chosung,
                    jungsung: state.jungsung,
                    jongsung: nil
                )
                let committed = composeSyllable(state: prevState)
                let newState = CompositionState(
                    chosung: newCho,
                    jungsung: jung,
                    composingBuffer: [input.rawChar]
                )
                return .committed(newState, char: committed)
            }

            // 변환 불가 → 전체 확정 + 새 초성 시작
            let committed = composeSyllable(state: state)
            let newState = CompositionState(
                chosung: cho,
                composingBuffer: [input.rawChar]
            )
            return .committed(newState, char: committed)
        }
    }

    // MARK: - 헬퍼

    /// 현재 상태를 한글 글자로 조합
    private func composeSyllable(state: CompositionState) -> String? {
        if let composer = HangulComposer(
            chosungPoint: state.chosung,
            jungsungPoint: state.jungsung,
            jongsungPoint: state.jongsung
        ) {
            if let char = composer.getSyllable() {
                return String(char)
            }
        }

        // 현대한글 조합 실패 시 NFD 시도
        return composeAlternative(state: state)
    }

    /// NFD 방식으로 조합 (옛한글 등)
    private func composeAlternative(state: CompositionState) -> String? {
        var unicodeScalars = String.UnicodeScalarView()

        if let cho = state.chosung {
            unicodeScalars.append(UnicodeScalar(cho.rawValue)!)
        }
        if let jung = state.jungsung {
            unicodeScalars.append(UnicodeScalar(jung.rawValue)!)
        }
        if let jong = state.jongsung {
            unicodeScalars.append(UnicodeScalar(jong.rawValue)!)
        }

        if unicodeScalars.count > 0 {
            return String(unicodeScalars)
        }
        return nil
    }
}

// MARK: - TransitionResult 확장

extension TransitionResult {
    /// 확정 글자 추가
    func with(committed: String?) -> TransitionResult {
        guard let existingCommit = committed else { return self }

        if let myCommit = self.committedChar {
            return TransitionResult(
                newState: newState,
                committedChar: existingCommit + myCommit,
                resultType: .committed
            )
        }
        return TransitionResult(
            newState: newState,
            committedChar: existingCommit,
            resultType: .committed
        )
    }
}
