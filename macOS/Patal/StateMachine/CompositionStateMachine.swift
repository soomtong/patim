//
//  CompositionStateMachine.swift
//  Patal
//
//  Created by dp on 1/25/26.
//

import Foundation

/// 한글 조합 상태 머신
/// 입력 이벤트를 받아 상태 전이를 수행하고 결과를 반환
struct CompositionStateMachine {
    /// 현재 버퍼 상태
    private(set) var buffer: SyllableBuffer

    /// 한글 자판 레이아웃
    private let layout: HangulAutomata

    init(layout: HangulAutomata) {
        self.layout = layout
        self.buffer = .empty
    }

    // MARK: - 메인 입력 처리

    /// rawKey를 받아 이벤트로 변환 후 처리
    /// - Parameter rawKey: 입력된 키 문자열
    /// - Returns: 상태 전이 결과
    mutating func processInput(_ rawKey: String) -> TransitionResult {
        // 키 히스토리에 추가
        buffer.appendKeyHistory(rawKey)

        // rawKey를 InputEvent로 변환
        guard let event = createEvent(from: rawKey) else {
            // 이벤트 생성 실패 시 히스토리에서 제거하고 invalid 반환
            buffer.removeLastKeyHistory()
            return .invalid
        }

        return processEvent(event, rawKey: rawKey)
    }

    /// rawKey를 InputEvent로 변환
    /// 현재 상태에 따라 검색 우선순위가 달라짐
    private func createEvent(from rawKey: String) -> InputEvent? {
        let state = buffer.state

        // 상태에 따른 우선순위 결정
        // 초성+중성 상태 또는 초성+중성+종성 상태에서는 종성을 먼저 체크
        // (같은 키가 중성과 종성에 모두 매핑된 경우 대응)
        switch state {
        case .consonantVowel, .consonantVowelFinal:
            // 종성 우선
            if let jongsungCode = layout.pickJongsung(by: rawKey),
               let jongsung = 종성(rawValue: jongsungCode)
            {
                return .jongsung(jongsung)
            }
            // 초성 확인
            if let chosungCode = layout.pickChosung(by: rawKey),
               let chosung = 초성(rawValue: chosungCode)
            {
                return .chosung(chosung)
            }
            // 중성 확인 (겹모음)
            if let jungsungCode = layout.pickJungsung(by: rawKey),
               let jungsung = 중성(rawValue: jungsungCode)
            {
                return .jungsung(jungsung)
            }

        case .initialConsonant:
            // 초성만 있을 때: 중성 우선
            // 단, 모아주기 모드에서는 종성도 체크해야 함
            // 중성과 종성이 같은 키에 매핑된 경우, 중성 우선 (기존 동작 유지)
            if let jungsungCode = layout.pickJungsung(by: rawKey),
               let jungsung = 중성(rawValue: jungsungCode)
            {
                return .jungsung(jungsung)
            }
            // 모아주기 모드에서 종성 허용 (중성에 매핑되지 않은 키)
            if layout.can모아주기 {
                if let jongsungCode = layout.pickJongsung(by: rawKey),
                   let jongsung = 종성(rawValue: jongsungCode)
                {
                    return .jongsung(jongsung)
                }
            }
            // 겹자음 초성
            if let chosungCode = layout.pickChosung(by: rawKey),
               let chosung = 초성(rawValue: chosungCode)
            {
                return .chosung(chosung)
            }

        default:
            // 기본: 초성 → 중성 → 종성 순서
            if let chosungCode = layout.pickChosung(by: rawKey),
               let chosung = 초성(rawValue: chosungCode)
            {
                return .chosung(chosung)
            }
            if layout.can모아주기 {
                if let jungsungCode = layout.pickJungsung(by: rawKey),
                   let jungsung = 중성(rawValue: jungsungCode)
                {
                    return .jungsung(jungsung)
                }
            }
            if let jongsungCode = layout.pickJongsung(by: rawKey),
               let jongsung = 종성(rawValue: jongsungCode)
            {
                return .jongsung(jongsung)
            }
            if !layout.can모아주기 {
                if let jungsungCode = layout.pickJungsung(by: rawKey),
                   let jungsung = 중성(rawValue: jungsungCode)
                {
                    return .jungsung(jungsung)
                }
            }
        }

        return nil
    }

    // MARK: - 이벤트 처리 (carryoverEvent 패턴)

    /// 이벤트 처리 (재귀 대신 루프 사용)
    /// - Parameters:
    ///   - event: 입력 이벤트
    ///   - rawKey: 원본 키 (composing 버퍼용)
    /// - Returns: 상태 전이 결과
    private mutating func processEvent(_ event: InputEvent, rawKey: String) -> TransitionResult {
        var currentEvent: InputEvent? = event
        var currentRawKey: String? = rawKey
        var committedString = ""

        while let ev = currentEvent {
            let output = transition(from: buffer.state, with: ev, rawKey: currentRawKey)

            switch output.action {
            case .updateBuffer:
                buffer = output.nextBuffer
                currentEvent = nil

            case .commitAndContinue:
                committedString += output.committed ?? ""
                buffer = output.nextBuffer
                currentEvent = output.carryoverEvent
                // carryover 이벤트는 이미 히스토리에 기록된 키를 재처리하는 것이므로
                // rawKey는 nil로 설정 (composing에 다시 추가하지 않음)
                currentRawKey = nil
            }
        }

        if !committedString.isEmpty {
            return .commit(committedString, nextBuffer: buffer)
        }
        return .composing(buffer)
    }

    // MARK: - 상태 전이 규칙

    /// 상태와 이벤트에 따른 전이 수행
    private func transition(
        from state: CompositionState,
        with event: InputEvent,
        rawKey: String?
    ) -> TransitionOutput {
        switch (state, event) {
        // MARK: Empty 상태
        case (.empty, .chosung(let cho)):
            return handleEmptyChosung(cho, rawKey: rawKey)

        case (.empty, .jungsung(let jung)):
            return handleEmptyJungsung(jung, rawKey: rawKey)

        case (.empty, .jongsung(let jong)):
            return handleEmptyJongsung(jong, rawKey: rawKey)

        // MARK: InitialConsonant 상태 (초성만)
        case (.initialConsonant, .jungsung(let jung)):
            return handleInitialConsonantJungsung(jung, rawKey: rawKey)

        case (.initialConsonant, .jongsung(let jong)):
            return handleInitialConsonantJongsung(jong, rawKey: rawKey)

        case (.initialConsonant, .chosung(let cho)):
            return handleInitialConsonantChosung(cho, rawKey: rawKey)

        // MARK: VowelOnly 상태 (중성만 - 모아주기)
        case (.vowelOnly, .chosung(let cho)):
            return handleVowelOnlyChosung(cho, rawKey: rawKey)

        case (.vowelOnly, .jongsung(let jong)):
            return handleVowelOnlyJongsung(jong, rawKey: rawKey)

        case (.vowelOnly, .jungsung(let jung)):
            return handleVowelOnlyJungsung(jung, rawKey: rawKey)

        // MARK: FinalOnly 상태 (종성만 - 모아주기)
        case (.finalOnly, .jongsung(let jong)):
            return handleFinalOnlyJongsung(jong, rawKey: rawKey)

        case (.finalOnly, .chosung(let cho)):
            return handleFinalOnlyChosung(cho, rawKey: rawKey)

        case (.finalOnly, .jungsung(let jung)):
            return handleFinalOnlyJungsung(jung, rawKey: rawKey)

        // MARK: ConsonantVowel 상태 (초성+중성)
        case (.consonantVowel, .chosung(let cho)):
            return handleConsonantVowelChosung(cho, rawKey: rawKey)

        case (.consonantVowel, .jungsung(let jung)):
            return handleConsonantVowelJungsung(jung, rawKey: rawKey)

        case (.consonantVowel, .jongsung(let jong)):
            return handleConsonantVowelJongsung(jong, rawKey: rawKey)

        // MARK: VowelFinal 상태 (중성+종성 - 모아주기)
        case (.vowelFinal, .chosung(let cho)):
            return handleVowelFinalChosung(cho, rawKey: rawKey)

        case (.vowelFinal, _):
            // 중성+종성 상태에서 다른 입력은 커밋 후 새 글자
            return handleInvalidWithCommit(event: event)

        // MARK: ConsonantFinal 상태 (초성+종성 - 모아주기)
        case (.consonantFinal, .jungsung(let jung)):
            return handleConsonantFinalJungsung(jung, rawKey: rawKey)

        case (.consonantFinal, _):
            // 초성+종성 상태에서 다른 입력은 커밋 후 새 글자
            return handleInvalidWithCommit(event: event)

        // MARK: ConsonantVowelFinal 상태 (초성+중성+종성)
        case (.consonantVowelFinal, .jongsung(let jong)):
            return handleConsonantVowelFinalJongsung(jong, rawKey: rawKey)

        case (.consonantVowelFinal, .jungsung(let jung)):
            return handleConsonantVowelFinalJungsung(jung, rawKey: rawKey)

        case (.consonantVowelFinal, .chosung(let cho)):
            return handleConsonantVowelFinalChosung(cho, rawKey: rawKey)

        // MARK: Flush/Backspace
        case (_, .flush):
            return handleFlush()

        case (_, .backspace):
            return handleBackspace()
        }
    }

    // MARK: - Empty 상태 핸들러

    /// Empty → InitialConsonant 전이
    /// - 예시: [] + ㄱ → [ㄱ]
    /// - 조건: 버퍼가 비어있을 때 초성 입력
    /// - 결과: 버퍼에 초성 추가, composingKeys 업데이트
    private func handleEmptyChosung(_ cho: 초성, rawKey: String?) -> TransitionOutput {
        var newBuffer = buffer
        newBuffer.chosung = cho
        if let key = rawKey {
            newBuffer.appendComposingKey(key)
        }
        return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
    }

    /// Empty → VowelOnly 전이 (모아주기 전용)
    /// - 예시: [] + ㅏ → [ㅏ] (모아주기 활성화)
    /// - 조건: 모아주기 모드에서 중성 단독 입력
    /// - 결과 (성공): 버퍼에 중성 추가
    /// - 결과 (실패): 모아주기 비활성화 시 버퍼 유지 (무시)
    private func handleEmptyJungsung(_ jung: 중성, rawKey: String?) -> TransitionOutput {
        guard layout.can모아주기 else {
            // 모아주기가 아니면 invalid
            return TransitionOutput(action: .updateBuffer, nextBuffer: buffer)
        }
        var newBuffer = buffer
        newBuffer.jungsung = jung
        if let key = rawKey {
            newBuffer.appendComposingKey(key)
        }
        return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
    }

    /// Empty → FinalOnly 전이
    /// - 예시: [] + ㄱ(종성) → [ㄱ]
    /// - 조건: 버퍼가 비어있을 때 종성 입력 (특수 자판 배열)
    /// - 결과: 버퍼에 종성 추가, composingKeys 업데이트
    private func handleEmptyJongsung(_ jong: 종성, rawKey: String?) -> TransitionOutput {
        var newBuffer = buffer
        newBuffer.jongsung = jong
        if let key = rawKey {
            newBuffer.appendComposingKey(key)
        }
        return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
    }

    // MARK: - InitialConsonant 상태 핸들러

    /// InitialConsonant → ConsonantVowel 전이
    /// - 예시: [ㄱ] + ㅏ → [가]
    /// - 조건: 초성만 있는 상태에서 중성 입력
    /// - 결과: 버퍼에 중성 추가, composingKeys 리셋
    private func handleInitialConsonantJungsung(_ jung: 중성, rawKey: String?) -> TransitionOutput {
        var newBuffer = buffer
        newBuffer.jungsung = jung
        newBuffer.resetComposingKeys(rawKey ?? "")
        return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
    }

    /// InitialConsonant → ConsonantFinal 전이 (모아주기) 또는 커밋 후 새 초성
    /// - 예시 (모아주기): [ㄱ] + ㄴ(종성) → [ㄱ+ㄴ] (초성+종성)
    /// - 예시 (일반): [ㄱ] + ㄴ(종성) → 커밋 "ㄱ" + [ㄴ]
    /// - 조건 (모아주기): 종성을 그대로 추가
    /// - 조건 (일반): 종성→초성 변환 후 커밋, 새 버퍼에 초성 설정
    private func handleInitialConsonantJongsung(_ jong: 종성, rawKey: String?) -> TransitionOutput {
        if layout.can모아주기 {
            var newBuffer = buffer
            newBuffer.jongsung = jong
            newBuffer.resetComposingKeys(rawKey ?? "")
            return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
        }

        // 모아주기 비활성화: 종성에 해당하는 자음을 초성으로 변환
        if let chosung = jongsungToChosung(jong) {
            let committed = composeString(from: buffer)
            var newBuffer = SyllableBuffer.empty
            newBuffer.chosung = chosung
            newBuffer.resetComposingKeys(rawKey ?? "")
            newBuffer.keyHistory = [rawKey ?? ""]
            return TransitionOutput(
                action: .commitAndContinue,
                nextBuffer: newBuffer,
                committed: committed
            )
        }

        return TransitionOutput(action: .updateBuffer, nextBuffer: buffer)
    }

    /// InitialConsonant → InitialConsonant 전이 (겹자음) 또는 커밋 후 새 초성
    /// - 예시 (겹자음 성공): [ㄱ] + ㄱ → [ㄲ]
    /// - 예시 (겹자음 실패): [ㄱ] + ㄴ → 커밋 "ㄱ" + [ㄴ]
    /// - 조건 (성공): composingKeys 결합이 유효한 겹자음일 때
    /// - 조건 (실패): 결합 불가 시 현재 글자 커밋, 새 버퍼에 초성 설정
    private func handleInitialConsonantChosung(_ cho: 초성, rawKey: String?) -> TransitionOutput {
        // 겹자음 시도
        var testComposing = buffer.composingKeys
        if let key = rawKey {
            testComposing.append(key)
        }

        if let combinedCode = layout.pickChosung(by: testComposing.joined()),
           let combined = 초성(rawValue: combinedCode)
        {
            var newBuffer = buffer
            newBuffer.chosung = combined
            if let key = rawKey {
                newBuffer.appendComposingKey(key)
            }
            return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
        }

        // 겹자음 실패: 현재 글자 커밋 후 새 초성
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.chosung = cho
        newBuffer.resetComposingKeys(rawKey ?? "")
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    // MARK: - VowelOnly 상태 핸들러 (모아주기)

    /// VowelOnly → ConsonantVowel 전이 (모아주기)
    /// - 예시: [ㅏ] + ㄱ → [가]
    /// - 조건: 중성만 있는 상태에서 초성 입력
    /// - 결과: 버퍼에 초성 추가 (모아주기로 초+중 완성)
    private func handleVowelOnlyChosung(_ cho: 초성, rawKey: String?) -> TransitionOutput {
        var newBuffer = buffer
        newBuffer.chosung = cho
        return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
    }

    /// VowelOnly → VowelFinal 전이 (모아주기) 또는 커밋 후 새 종성
    /// - 예시 (모아주기): [ㅏ] + ㄱ(종성) → [ㅏ+ㄱ] (중성+종성)
    /// - 예시 (일반): [ㅏ] + ㄱ(종성) → 커밋 "ㅏ" + [ㄱ]
    /// - 조건 (모아주기): 종성 추가
    /// - 조건 (일반): 현재 글자 커밋, 새 버퍼에 종성 설정
    private func handleVowelOnlyJongsung(_ jong: 종성, rawKey: String?) -> TransitionOutput {
        if layout.can모아주기 {
            var newBuffer = buffer
            newBuffer.jongsung = jong
            return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
        }

        // 모아주기 아닌 경우 커밋 후 새 글자
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.jongsung = jong
        newBuffer.resetComposingKeys(rawKey ?? "")
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    /// VowelOnly → VowelOnly 전이 (겹모음) 또는 커밋 후 새 중성
    /// - 예시 (겹모음 성공): [ㅗ] + ㅏ → [ㅘ]
    /// - 예시 (겹모음 실패): [ㅏ] + ㅓ → 커밋 "ㅏ" + [ㅓ]
    /// - 조건 (성공): composingKeys 결합이 유효한 겹모음일 때
    /// - 조건 (실패): 결합 불가 시 현재 글자 커밋, 새 버퍼에 중성 설정
    private func handleVowelOnlyJungsung(_ jung: 중성, rawKey: String?) -> TransitionOutput {
        // 겹모음 시도
        var testComposing = buffer.composingKeys
        if let key = rawKey {
            testComposing.append(key)
        }

        if let combinedCode = layout.pickJungsung(by: testComposing.joined()),
           let combined = 중성(rawValue: combinedCode)
        {
            var newBuffer = buffer
            newBuffer.jungsung = combined
            if let key = rawKey {
                newBuffer.appendComposingKey(key)
            }
            return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
        }

        // 겹모음 실패: 커밋 후 새 중성
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.jungsung = jung
        newBuffer.resetComposingKeys(rawKey ?? "")
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    // MARK: - FinalOnly 상태 핸들러 (종성만)

    /// FinalOnly → FinalOnly 전이 (겹받침) 또는 커밋 후 새 종성
    /// - 예시 (겹받침 성공): [ㄱ] + ㅅ → [ㄳ]
    /// - 예시 (겹받침 실패): [ㄱ] + ㄴ → 커밋 "ㄱ" + [ㄴ]
    /// - 조건 (성공): composingKeys 결합이 유효한 겹받침일 때
    /// - 조건 (실패): 결합 불가 시 현재 글자 커밋, 새 버퍼에 종성 설정
    private func handleFinalOnlyJongsung(_ jong: 종성, rawKey: String?) -> TransitionOutput {
        // 겹받침 시도
        var testComposing = buffer.composingKeys
        if let key = rawKey {
            testComposing.append(key)
        }

        if let combinedCode = layout.pickJongsung(by: testComposing.joined()),
           let combined = 종성(rawValue: combinedCode)
        {
            var newBuffer = buffer
            newBuffer.jongsung = combined
            if let key = rawKey {
                newBuffer.appendComposingKey(key)
            }
            return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
        }

        // 겹받침 실패: 커밋 후 새 종성
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.jongsung = jong
        newBuffer.resetComposingKeys(rawKey ?? "")
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    /// FinalOnly → ConsonantFinal 전이 (모아주기) 또는 커밋 후 새 초성
    /// - 예시 (모아주기): [ㄱ(종성)] + ㄴ(초성) → [ㄴ+ㄱ] (초성+종성)
    /// - 예시 (일반): [ㄱ(종성)] + ㄴ(초성) → 커밋 "ㄱ" + [ㄴ]
    /// - 조건 (모아주기): 초성 추가
    /// - 조건 (일반): 현재 글자 커밋, 새 버퍼에 초성 설정
    private func handleFinalOnlyChosung(_ cho: 초성, rawKey: String?) -> TransitionOutput {
        if layout.can모아주기 {
            var newBuffer = buffer
            newBuffer.chosung = cho
            return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
        }

        // 모아주기 아닌 경우 커밋 후 새 초성
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.chosung = cho
        newBuffer.resetComposingKeys(rawKey ?? "")
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    /// FinalOnly → VowelFinal 전이 (모아주기) 또는 커밋 후 새 중성
    /// - 예시 (모아주기): [ㄱ(종성)] + ㅏ → [ㅏ+ㄱ] (중성+종성)
    /// - 예시 (일반): [ㄱ(종성)] + ㅏ → 커밋 "ㄱ" + [ㅏ]
    /// - 조건 (모아주기): 중성 추가
    /// - 조건 (일반): 현재 글자 커밋, 새 버퍼에 중성 설정
    private func handleFinalOnlyJungsung(_ jung: 중성, rawKey: String?) -> TransitionOutput {
        if layout.can모아주기 {
            var newBuffer = buffer
            newBuffer.jungsung = jung
            return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
        }

        // 모아주기 아닌 경우 커밋 후 새 중성
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.jungsung = jung
        newBuffer.resetComposingKeys(rawKey ?? "")
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    // MARK: - ConsonantVowel 상태 핸들러 (초성+중성)

    /// ConsonantVowel → InitialConsonant 전이 (커밋 후 새 초성)
    /// - 예시: [가] + ㄴ(초성) → 커밋 "가" + [ㄴ]
    /// - 조건: 초성+중성 상태에서 새 초성 입력
    /// - 결과: 현재 글자 커밋, 새 버퍼에 초성 설정
    private func handleConsonantVowelChosung(_ cho: 초성, rawKey: String?) -> TransitionOutput {
        // 초성+중성 상태에서 새 초성: 커밋 후 새 글자
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.chosung = cho
        if let key = rawKey {
            newBuffer.appendComposingKey(key)
        }
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    /// ConsonantVowel → ConsonantVowel 전이 (겹모음) 또는 커밋 후 새 중성
    /// - 예시 (겹모음 성공): [고] + ㅏ → [과]
    /// - 예시 (겹모음 실패, 모아주기): [가] + ㅓ → 커밋 "가" + [ㅓ]
    /// - 조건 (성공): composingKeys 결합이 유효한 겹모음일 때
    /// - 조건 (실패): 결합 불가 시 모아주기면 커밋, 아니면 무시
    private func handleConsonantVowelJungsung(_ jung: 중성, rawKey: String?) -> TransitionOutput {
        // 겹모음 시도
        if buffer.composingKeys.count > 0 {
            var testComposing = buffer.composingKeys
            if let key = rawKey {
                testComposing.append(key)
            }

            if let combinedCode = layout.pickJungsung(by: testComposing.joined()),
               let combined = 중성(rawValue: combinedCode)
            {
                var newBuffer = buffer
                newBuffer.jungsung = combined
                if let key = rawKey {
                    newBuffer.appendComposingKey(key)
                }
                return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
            }
        }

        // 겹모음 실패: 커밋 후 새 중성 (모아주기일 때만)
        if layout.can모아주기 {
            let committed = composeString(from: buffer)
            var newBuffer = SyllableBuffer.empty
            newBuffer.jungsung = jung
            newBuffer.resetComposingKeys(rawKey ?? "")
            newBuffer.keyHistory = [rawKey ?? ""]
            return TransitionOutput(
                action: .commitAndContinue,
                nextBuffer: newBuffer,
                committed: committed
            )
        }

        return TransitionOutput(action: .updateBuffer, nextBuffer: buffer)
    }

    /// ConsonantVowel → ConsonantVowelFinal 전이
    /// - 예시: [가] + ㄴ(종성) → [간]
    /// - 조건: 초성+중성 상태에서 종성 입력
    /// - 결과: 버퍼에 종성 추가, composingKeys 리셋
    private func handleConsonantVowelJongsung(_ jong: 종성, rawKey: String?) -> TransitionOutput {
        var newBuffer = buffer
        newBuffer.jongsung = jong
        newBuffer.resetComposingKeys(rawKey ?? "")
        return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
    }

    // MARK: - VowelFinal 상태 핸들러 (중성+종성 - 모아주기)

    /// VowelFinal → ConsonantVowelFinal 전이 (모아주기)
    /// - 예시: [ㅏ+ㄱ] + ㄴ(초성) → [난] (중성+종성에 초성 결합)
    /// - 조건: 중성+종성 상태에서 초성 입력 (모아주기)
    /// - 결과: 버퍼에 초성 추가하여 완성된 글자
    private func handleVowelFinalChosung(_ cho: 초성, rawKey: String?) -> TransitionOutput {
        var newBuffer = buffer
        newBuffer.chosung = cho
        return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
    }

    // MARK: - ConsonantFinal 상태 핸들러 (초성+종성 - 모아주기)

    /// ConsonantFinal → ConsonantVowelFinal 전이 (모아주기)
    /// - 예시: [ㄱ+ㄴ] + ㅏ → [간] (초성+종성에 중성 결합)
    /// - 조건: 초성+종성 상태에서 중성 입력 (모아주기)
    /// - 결과: 버퍼에 중성 추가하여 완성된 글자
    private func handleConsonantFinalJungsung(_ jung: 중성, rawKey: String?) -> TransitionOutput {
        var newBuffer = buffer
        newBuffer.jungsung = jung
        return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
    }

    // MARK: - ConsonantVowelFinal 상태 핸들러 (초성+중성+종성)

    /// ConsonantVowelFinal → ConsonantVowelFinal 전이 (겹받침) 또는 커밋 후 새 종성
    /// - 예시 (겹받침 성공): [간] + ㅅ → [값] (ㄴ+ㅅ=ㄵ)
    /// - 예시 (겹받침 실패): [간] + ㄱ → 커밋 "간" + [ㄱ]
    /// - 조건 (성공): composingKeys 결합이 유효한 겹받침일 때
    /// - 조건 (실패): 결합 불가 시 현재 글자 커밋, 새 버퍼에 종성 설정
    private func handleConsonantVowelFinalJongsung(
        _ jong: 종성,
        rawKey: String?
    ) -> TransitionOutput {
        // 겹받침 시도
        var testComposing = buffer.composingKeys
        if let key = rawKey {
            testComposing.append(key)
        }

        if let combinedCode = layout.pickJongsung(by: testComposing.joined()),
           let combined = 종성(rawValue: combinedCode)
        {
            var newBuffer = buffer
            newBuffer.jongsung = combined
            if let key = rawKey {
                newBuffer.appendComposingKey(key)
            }
            return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
        }

        // 겹받침 실패: 커밋 후 새 글자
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.jongsung = jong
        newBuffer.resetComposingKeys(rawKey ?? "")
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    /// ConsonantVowelFinal → VowelOnly 전이 (커밋 후 새 중성)
    /// - 예시: [간] + ㅏ → 커밋 "간" + [ㅏ]
    /// - 조건: 완성된 글자에서 중성 입력 (세벌식)
    /// - 결과: 현재 글자 커밋, 새 버퍼에 중성 설정
    /// - 참고: 세벌식은 종성 분리 없음 (두벌식과 다름)
    private func handleConsonantVowelFinalJungsung(
        _ jung: 중성,
        rawKey: String?
    ) -> TransitionOutput {
        // 세벌식: 종성 분리 없이 현재 글자 커밋 후 새 중성 시작
        // (두벌식과 달리 종성을 초성으로 변환하지 않음)
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.jungsung = jung
        newBuffer.resetComposingKeys(rawKey ?? "")
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    /// ConsonantVowelFinal → InitialConsonant 전이 (커밋 후 새 초성)
    /// - 예시: [간] + ㄱ(초성) → 커밋 "간" + [ㄱ]
    /// - 조건: 완성된 글자에서 초성 입력
    /// - 결과: 현재 글자 커밋, 새 버퍼에 초성 설정
    private func handleConsonantVowelFinalChosung(
        _ cho: 초성,
        rawKey: String?
    ) -> TransitionOutput {
        // 완성된 글자 커밋 후 새 초성
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty
        newBuffer.chosung = cho
        if let key = rawKey {
            newBuffer.appendComposingKey(key)
        }
        newBuffer.keyHistory = [rawKey ?? ""]
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    // MARK: - 공통 핸들러

    /// 모든 상태 → Empty 전이 (버퍼 플러시)
    /// - 예시: [간] + flush → 커밋 "간" + []
    /// - 조건: flush 이벤트 발생 (Enter, 포커스 이동 등)
    /// - 결과: 현재 버퍼 내용 커밋, 버퍼 초기화
    private func handleFlush() -> TransitionOutput {
        let committed = composeString(from: buffer)
        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: .empty,
            committed: committed.isEmpty ? nil : committed
        )
    }

    /// 백스페이스 처리 (키 히스토리 기반)
    /// - 예시: [간] + backspace → [가] (히스토리 재계산)
    /// - 예시: [ㄱ] + backspace → []
    /// - 조건: backspace 이벤트 발생
    /// - 결과: 키 히스토리에서 마지막 제거, 외부에서 재계산 필요
    private func handleBackspace() -> TransitionOutput {
        // 키 히스토리에서 마지막 제거 후 재계산
        // 실제 구현은 recomputeFromHistory 패턴 사용
        var newBuffer = buffer
        guard newBuffer.removeLastKeyHistory() != nil else {
            return TransitionOutput(action: .updateBuffer, nextBuffer: .empty)
        }

        if newBuffer.keyHistory.isEmpty {
            return TransitionOutput(action: .updateBuffer, nextBuffer: .empty)
        }

        // 히스토리 기반 재계산은 외부에서 처리
        return TransitionOutput(action: .updateBuffer, nextBuffer: newBuffer)
    }

    /// 유효하지 않은 전이 처리 (커밋 후 새 글자)
    /// - 예시: [ㅏ+ㄱ] + ㅓ → 커밋 "ㅏㄱ" + [ㅓ] (VowelFinal에서 중성 입력)
    /// - 조건: 현재 상태에서 허용되지 않는 입력
    /// - 결과: 현재 버퍼 커밋, 새 버퍼에 입력 이벤트 설정
    private func handleInvalidWithCommit(event: InputEvent) -> TransitionOutput {
        let committed = composeString(from: buffer)
        var newBuffer = SyllableBuffer.empty

        switch event {
        case .chosung(let cho):
            newBuffer.chosung = cho
        case .jungsung(let jung):
            newBuffer.jungsung = jung
        case .jongsung(let jong):
            newBuffer.jongsung = jong
        default:
            break
        }

        return TransitionOutput(
            action: .commitAndContinue,
            nextBuffer: newBuffer,
            committed: committed
        )
    }

    // MARK: - 유틸리티

    /// 버퍼를 한글 문자열로 조합
    private func composeString(from buffer: SyllableBuffer) -> String {
        guard !buffer.isEmpty else { return "" }

        if let composer = HangulComposer(
            chosungPoint: buffer.chosung,
            jungsungPoint: buffer.jungsung,
            jongsungPoint: buffer.jongsung
        ), let char = composer.getSyllable() {
            return String(char)
        }

        // 현대한글 조합 실패 시 NFD로 제공
        return composeAlternative(from: buffer)
    }

    /// NFD 형태로 조합 (옛한글 등)
    private func composeAlternative(from buffer: SyllableBuffer) -> String {
        var scalars = String.UnicodeScalarView()

        if let cho = buffer.chosung {
            if let scalar = UnicodeScalar(cho.rawValue) {
                scalars.append(scalar)
            }
        }
        if let jung = buffer.jungsung {
            if let scalar = UnicodeScalar(jung.rawValue) {
                scalars.append(scalar)
            }
        }
        if let jong = buffer.jongsung {
            if let scalar = UnicodeScalar(jong.rawValue) {
                scalars.append(scalar)
            }
        }

        return String(scalars)
    }

    /// 겹받침 분리 (예: ㄺ -> ㄹ + ㄱ)
    private func splitDoubleJongsung(_ jongsung: 종성) -> (종성, 초성)? {
        switch jongsung {
        case .기역시옷: return (.기역, .시옷)
        case .니은지읒: return (.니은, .지읒)
        case .니은히읗: return (.니은, .히읗)
        case .리을기역: return (.리을, .기역)
        case .리을미음: return (.리을, .미음)
        case .리을비읍: return (.리을, .비읍)
        case .리을시옷: return (.리을, .시옷)
        case .리을티긑: return (.리을, .티긑)
        case .리을피읖: return (.리을, .피읖)
        case .리을히읗: return (.리을, .히읗)
        case .비읍시옷: return (.비읍, .시옷)
        default: return nil
        }
    }

    // MARK: - 백스페이스 리플레이

    /// 키 히스토리를 기반으로 상태 재계산
    mutating func applyBackspace() -> TransitionResult {
        guard !buffer.keyHistory.isEmpty else {
            return .composing(.empty)
        }

        let savedHistory = buffer.keyHistory
        buffer = .empty

        // 히스토리에서 마지막 하나 제외하고 재생
        let replayHistory = Array(savedHistory.dropLast())

        if replayHistory.isEmpty {
            return .composing(.empty)
        }

        for key in replayHistory {
            let result = processInput(key)
            // 커밋이 발생하면 무시 (백스페이스 중간 결과)
            if case .commit = result {
                // 커밋된 문자는 버리고 버퍼 상태만 유지
            }
        }

        // keyHistory를 재생된 키들로 복원
        buffer.keyHistory = replayHistory

        return .composing(buffer)
    }

    // MARK: - 외부 접근

    /// 현재 버퍼 상태 반환
    var currentState: CompositionState {
        return buffer.state
    }

    /// 버퍼 직접 설정 (마이그레이션용)
    mutating func setBuffer(_ newBuffer: SyllableBuffer) {
        buffer = newBuffer
    }

    /// 버퍼 초기화
    mutating func reset() {
        buffer = .empty
    }

    // MARK: - 버퍼 조작 헬퍼 (HangulProcessor 호환용)

    /// keyHistory에 키 추가
    mutating func appendKeyHistory(_ key: String) {
        buffer.appendKeyHistory(key)
    }

    /// keyHistory에서 마지막 키 제거
    @discardableResult
    mutating func removeLastKeyHistory() -> String? {
        return buffer.removeLastKeyHistory()
    }

    /// composingKeys 초기화 후 새 키 설정
    mutating func resetComposingKeys(_ key: String) {
        buffer.resetComposingKeys(key)
    }

    /// preedit만 초기화 (keyHistory 유지)
    mutating func clearPreedit() {
        buffer.clearPreedit()
    }

    /// keyHistory 설정
    mutating func setKeyHistory(_ history: [String]) {
        buffer.keyHistory = history
    }

    /// keyHistory 가져오기
    var keyHistory: [String] {
        return buffer.keyHistory
    }

    /// keyHistory 모두 제거
    mutating func clearKeyHistory() {
        buffer.keyHistory.removeAll()
    }
}
