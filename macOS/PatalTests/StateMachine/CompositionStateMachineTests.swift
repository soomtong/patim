//
//  CompositionStateMachineTests.swift
//  PatalTests
//
//  상태 기계 전이 테스트
//

import Testing

@testable import Patal

@Suite("CompositionStateMachine 테스트")
struct CompositionStateMachineTests {

    // MARK: - 테스트 헬퍼

    func createStateMachine() -> CompositionStateMachine {
        let layout = createLayoutInstance(name: .HAN3_P3)
        return CompositionStateMachine(layout: layout)
    }

    // MARK: - Empty 상태 테스트

    @Test("Empty → InitialConsonant: 초성 입력")
    func testEmptyToInitialConsonant() {
        let stateMachine = createStateMachine()
        let input = JamoInput.chosung(.기역, rawChar: "k")

        let result = stateMachine.transition(from: .empty, with: .jamo(input))

        #expect(result.newState.inputState == .initialConsonant)
        #expect(result.newState.chosung == .기역)
        #expect(result.committedChar == nil)
        #expect(result.resultType == .composing)
    }

    @Test("Empty 상태에서 Backspace는 변화 없음")
    func testEmptyBackspace() {
        let stateMachine = createStateMachine()

        let result = stateMachine.transition(from: .empty, with: .backspace)

        #expect(result.newState == .empty)
        #expect(result.resultType == .unchanged)
    }

    // MARK: - InitialConsonant 상태 테스트

    @Test("InitialConsonant → ConsonantVowel: 중성 입력")
    func testInitialConsonantToConsonantVowel() {
        let stateMachine = createStateMachine()
        let state = CompositionState(chosung: .기역, composingBuffer: ["k"])
        let input = JamoInput.jungsung(.아, rawChar: "f")

        let result = stateMachine.transition(from: state, with: .jamo(input))

        #expect(result.newState.inputState == .consonantVowel)
        #expect(result.newState.chosung == .기역)
        #expect(result.newState.jungsung == .아)
        #expect(result.resultType == .composing)
    }

    @Test("InitialConsonant → Empty: Backspace로 초성 삭제")
    func testInitialConsonantBackspace() {
        let stateMachine = createStateMachine()
        let state = CompositionState(chosung: .기역, composingBuffer: ["k"])

        let result = stateMachine.transition(from: state, with: .backspace)

        #expect(result.newState == .empty)
        #expect(result.resultType == .cleared)
    }

    // MARK: - ConsonantVowel 상태 테스트

    @Test("ConsonantVowel → ConsonantVowelFinal: 종성 입력")
    func testConsonantVowelToFinal() {
        let stateMachine = createStateMachine()
        let state = CompositionState(chosung: .기역, jungsung: .아, composingBuffer: ["f"])
        let input = JamoInput.jongsung(.이응, rawChar: "a")

        let result = stateMachine.transition(from: state, with: .jamo(input))

        #expect(result.newState.inputState == .consonantVowelFinal)
        #expect(result.newState.chosung == .기역)
        #expect(result.newState.jungsung == .아)
        #expect(result.newState.jongsung == .이응)
        #expect(result.resultType == .composing)
    }

    @Test("ConsonantVowel → InitialConsonant: Backspace로 중성 삭제")
    func testConsonantVowelBackspace() {
        let stateMachine = createStateMachine()
        let state = CompositionState(chosung: .기역, jungsung: .아, composingBuffer: ["f"])

        let result = stateMachine.transition(from: state, with: .backspace)

        #expect(result.newState.inputState == .initialConsonant)
        #expect(result.newState.chosung == .기역)
        #expect(result.newState.jungsung == nil)
        #expect(result.resultType == .composing)
    }

    @Test("ConsonantVowel + 새 초성 → 이전 글자 확정")
    func testConsonantVowelNewChosung() {
        let stateMachine = createStateMachine()
        let state = CompositionState(chosung: .기역, jungsung: .아, composingBuffer: ["f"])
        let input = JamoInput.chosung(.니은, rawChar: "h")

        let result = stateMachine.transition(from: state, with: .jamo(input))

        #expect(result.newState.inputState == .initialConsonant)
        #expect(result.newState.chosung == .니은)
        #expect(result.committedChar == "가")
        #expect(result.resultType == .committed)
    }

    // MARK: - ConsonantVowelFinal 상태 테스트

    @Test("ConsonantVowelFinal → ConsonantVowel: Backspace로 종성 삭제")
    func testConsonantVowelFinalBackspace() {
        let stateMachine = createStateMachine()
        let state = CompositionState(
            chosung: .기역,
            jungsung: .아,
            jongsung: .이응,
            composingBuffer: ["a"]
        )

        let result = stateMachine.transition(from: state, with: .backspace)

        #expect(result.newState.inputState == .consonantVowel)
        #expect(result.newState.chosung == .기역)
        #expect(result.newState.jungsung == .아)
        #expect(result.newState.jongsung == nil)
        #expect(result.resultType == .composing)
    }

    @Test("ConsonantVowelFinal + 중성 → 종성 분리")
    func testConsonantVowelFinalSplit() {
        let stateMachine = createStateMachine()
        let state = CompositionState(
            chosung: .기역,
            jungsung: .아,
            jongsung: .이응,
            composingBuffer: ["a"]
        )
        let input = JamoInput.jungsung(.아, rawChar: "f")

        let result = stateMachine.transition(from: state, with: .jamo(input))

        // "강" + 새 글자 "아" 시작 → "강" 확정, "아" 조합 시작 (이응이 초성으로 변환)
        #expect(result.committedChar == "가")
        #expect(result.newState.chosung == .이응)
        #expect(result.newState.jungsung == .아)
        #expect(result.resultType == .committed)
    }

    // MARK: - Commit/Cancel 테스트

    @Test("조합 중 commit → 글자 확정")
    func testCommit() {
        let stateMachine = createStateMachine()
        let state = CompositionState(chosung: .기역, jungsung: .아, jongsung: .이응)

        let result = stateMachine.transition(from: state, with: .commit)

        #expect(result.newState == .empty)
        #expect(result.committedChar == "강")
        #expect(result.resultType == .cleared)
    }

    @Test("조합 중 cancel → 글자 확정 (포커스 변경)")
    func testCancel() {
        let stateMachine = createStateMachine()
        let state = CompositionState(chosung: .니은, jungsung: .오)

        let result = stateMachine.transition(from: state, with: .cancel)

        #expect(result.newState == .empty)
        #expect(result.committedChar == "노")
        #expect(result.resultType == .cleared)
    }

    @Test("빈 상태에서 commit → 변화 없음")
    func testEmptyCommit() {
        let stateMachine = createStateMachine()

        let result = stateMachine.transition(from: .empty, with: .commit)

        #expect(result.newState == .empty)
        #expect(result.committedChar == nil)
        #expect(result.resultType == .unchanged)
    }
}

// MARK: - CompositionState 테스트

@Suite("CompositionState 테스트")
struct CompositionStateTests {

    @Test("빈 상태 생성")
    func testEmptyState() {
        let state = CompositionState.empty

        #expect(state.chosung == nil)
        #expect(state.jungsung == nil)
        #expect(state.jongsung == nil)
        #expect(state.inputState == .empty)
        #expect(state.isComposing == false)
    }

    @Test("inputState 계산 - 초성만")
    func testInputStateInitialConsonant() {
        let state = CompositionState(chosung: .기역)

        #expect(state.inputState == .initialConsonant)
        #expect(state.isComposing == true)
    }

    @Test("inputState 계산 - 초성+중성")
    func testInputStateConsonantVowel() {
        let state = CompositionState(chosung: .기역, jungsung: .아)

        #expect(state.inputState == .consonantVowel)
    }

    @Test("inputState 계산 - 완성형")
    func testInputStateComplete() {
        let state = CompositionState(chosung: .기역, jungsung: .아, jongsung: .이응)

        #expect(state.inputState == .consonantVowelFinal)
        #expect(state.composableCount == 3)
    }

    @Test("withChosung 불변성")
    func testWithChosungImmutability() {
        let original = CompositionState(jungsung: .아)
        let modified = original.withChosung(.기역)

        #expect(original.chosung == nil)
        #expect(modified.chosung == .기역)
        #expect(modified.jungsung == .아)
    }

    @Test("조합자 변환")
    func testTo조합자() {
        let state = CompositionState(chosung: .니은, jungsung: .오, jongsung: .리을)
        let preedit = state.to조합자()

        #expect(preedit.chosung == .니은)
        #expect(preedit.jungsung == .오)
        #expect(preedit.jongsung == .리을)
    }
}

// MARK: - SyllableRule 테스트

@Suite("DefaultSyllableRule 테스트")
struct SyllableRuleTests {

    let rule = DefaultSyllableRule()

    @Test("초성 → 종성 변환 가능 여부")
    func testCanBeFinal() {
        #expect(rule.canBeFinal(.기역) == true)
        #expect(rule.canBeFinal(.니은) == true)
        #expect(rule.canBeFinal(.쌍디귿) == false)  // ㄸ은 종성 불가
        #expect(rule.canBeFinal(.쌍비읍) == false)  // ㅃ은 종성 불가
    }

    @Test("겹받침 분리")
    func testSplitFinal() {
        let result = rule.canSplitFinal(.리을기역)

        #expect(result != nil)
        #expect(result?.first == .리을)
        #expect(result?.second == .기역)
    }

    @Test("단일 종성은 분리 불가")
    func testSingleFinalNoSplit() {
        let result = rule.canSplitFinal(.기역)

        #expect(result == nil)
    }

    @Test("초성 ↔ 종성 변환")
    func testChosungJongsungConversion() {
        #expect(rule.chosungToJongsung(.기역) == .기역)
        #expect(rule.jongsungToChosung(.기역) == .기역)
        #expect(rule.chosungToJongsung(.히읗) == .히흫)
        #expect(rule.jongsungToChosung(.히흫) == .히읗)
    }
}
