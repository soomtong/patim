//
//  StateTransitionTests.swift
//  PatalTests
//
//  Created by dp on 1/25/26.
//

import Testing

@testable import Patal

@Suite("CompositionState 테스트")
struct CompositionStateTests {
    @Test("상태 생성: empty")
    func testEmptyState() {
        let state = CompositionState.from(hasChosung: false, hasJungsung: false, hasJongsung: false)
        #expect(state == .empty)
        #expect(!state.isComposing)
        #expect(!state.canComposeModernHangul)
        #expect(!state.requiresMoachigi)
    }

    @Test("상태 생성: initialConsonant")
    func testInitialConsonantState() {
        let state = CompositionState.from(hasChosung: true, hasJungsung: false, hasJongsung: false)
        #expect(state == .initialConsonant)
        #expect(state.isComposing)
        #expect(!state.canComposeModernHangul)
    }

    @Test("상태 생성: vowelOnly (모아주기)")
    func testVowelOnlyState() {
        let state = CompositionState.from(hasChosung: false, hasJungsung: true, hasJongsung: false)
        #expect(state == .vowelOnly)
        #expect(state.requiresMoachigi)
    }

    @Test("상태 생성: finalOnly (모아주기)")
    func testFinalOnlyState() {
        let state = CompositionState.from(hasChosung: false, hasJungsung: false, hasJongsung: true)
        #expect(state == .finalOnly)
        #expect(state.requiresMoachigi)
    }

    @Test("상태 생성: consonantVowel")
    func testConsonantVowelState() {
        let state = CompositionState.from(hasChosung: true, hasJungsung: true, hasJongsung: false)
        #expect(state == .consonantVowel)
        #expect(state.canComposeModernHangul)
        #expect(!state.requiresMoachigi)
    }

    @Test("상태 생성: consonantVowelFinal")
    func testConsonantVowelFinalState() {
        let state = CompositionState.from(hasChosung: true, hasJungsung: true, hasJongsung: true)
        #expect(state == .consonantVowelFinal)
        #expect(state.canComposeModernHangul)
    }

    @Test("상태 생성: vowelFinal (모아주기)")
    func testVowelFinalState() {
        let state = CompositionState.from(hasChosung: false, hasJungsung: true, hasJongsung: true)
        #expect(state == .vowelFinal)
        #expect(state.requiresMoachigi)
    }

    @Test("상태 생성: consonantFinal (모아주기)")
    func testConsonantFinalState() {
        let state = CompositionState.from(hasChosung: true, hasJungsung: false, hasJongsung: true)
        #expect(state == .consonantFinal)
        #expect(state.requiresMoachigi)
    }
}

@Suite("SyllableBuffer 테스트")
struct SyllableBufferTests {
    @Test("빈 버퍼 상태")
    func testEmptyBuffer() {
        let buffer = SyllableBuffer.empty
        #expect(buffer.isEmpty)
        #expect(buffer.state == .empty)
        #expect(buffer.composableCount == 0)
    }

    @Test("버퍼에 초성 추가")
    func testBufferWithChosung() {
        var buffer = SyllableBuffer.empty
        buffer.chosung = .기역
        #expect(buffer.state == .initialConsonant)
        #expect(buffer.composableCount == 1)
    }

    @Test("버퍼에 초성+중성 추가")
    func testBufferWithChosungJungsung() {
        var buffer = SyllableBuffer.empty
        buffer.chosung = .기역
        buffer.jungsung = .아
        #expect(buffer.state == .consonantVowel)
        #expect(buffer.composableCount == 2)
    }

    @Test("조합자 변환")
    func testTo조합자() {
        var buffer = SyllableBuffer.empty
        buffer.chosung = .니은
        buffer.jungsung = .오
        buffer.jongsung = .리을

        let 조합 = buffer.to조합자()
        #expect(조합.chosung == .니은)
        #expect(조합.jungsung == .오)
        #expect(조합.jongsung == .리을)
    }

    @Test("composingKeys 관리")
    func testComposingKeys() {
        var buffer = SyllableBuffer.empty
        buffer.appendComposingKey("k")
        buffer.appendComposingKey("k")
        #expect(buffer.composingKeys == ["k", "k"])

        buffer.resetComposingKeys("f")
        #expect(buffer.composingKeys == ["f"])
    }

    @Test("keyHistory 관리")
    func testKeyHistory() {
        var buffer = SyllableBuffer.empty
        buffer.appendKeyHistory("k")
        buffer.appendKeyHistory("f")
        #expect(buffer.keyHistory == ["k", "f"])

        let removed = buffer.removeLastKeyHistory()
        #expect(removed == "f")
        #expect(buffer.keyHistory == ["k"])
    }
}

@Suite("InputEvent 테스트")
struct InputEventTests {
    @Test("초성 이벤트")
    func testChosungEvent() {
        let event = InputEvent.chosung(.기역)
        #expect(event.kind == .chosung)
        #expect(event.isJamo)
    }

    @Test("중성 이벤트")
    func testJungsungEvent() {
        let event = InputEvent.jungsung(.아)
        #expect(event.kind == .jungsung)
        #expect(event.isJamo)
    }

    @Test("종성 이벤트")
    func testJongsungEvent() {
        let event = InputEvent.jongsung(.기역)
        #expect(event.kind == .jongsung)
        #expect(event.isJamo)
    }

    @Test("백스페이스 이벤트")
    func testBackspaceEvent() {
        let event = InputEvent.backspace
        #expect(event.kind == .backspace)
        #expect(!event.isJamo)
    }

    @Test("flush 이벤트")
    func testFlushEvent() {
        let event = InputEvent.flush
        #expect(event.kind == .flush)
        #expect(!event.isJamo)
    }
}

@Suite("TransitionResult 테스트")
struct TransitionResultTests {
    @Test("composing 결과")
    func testComposingResult() {
        let buffer = SyllableBuffer.empty
        let result = TransitionResult.composing(buffer)

        #expect(result.isComposing)
        #expect(!result.isCommitted)
        #expect(result.buffer == buffer)
        #expect(result.committedString == nil)
        #expect(result.toCommitState == .composing)
    }

    @Test("commit 결과")
    func testCommitResult() {
        let buffer = SyllableBuffer.empty
        let result = TransitionResult.commit("가", nextBuffer: buffer)

        #expect(!result.isComposing)
        #expect(result.isCommitted)
        #expect(result.buffer == buffer)
        #expect(result.committedString == "가")
        #expect(result.toCommitState == .committed)
    }

    @Test("invalid 결과")
    func testInvalidResult() {
        let result = TransitionResult.invalid

        #expect(!result.isComposing)
        #expect(!result.isCommitted)
        #expect(result.buffer == nil)
        #expect(result.toCommitState == .none)
    }
}
