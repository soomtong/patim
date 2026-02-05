//
//  InputStrategyTests.swift
//  PatalTests
//
//  Created by dp on 2/5/25.
//

import Testing

@testable import Patal

// MARK: - InputStrategy 판별 테스트
//
// InputStrategy.determine(from:)는 클라이언트의 validAttributesForMarkedText 결과를 받아
// directInsert 또는 swapMarked 전략을 결정한다.
//
// directInsert 조건 (Sok 입력기 참고):
//   - NSTextAlternatives 포함
//   - NSMarkedClauseSegment + NSFont 포함
//   - NSMarkedClauseSegment + NSGlyphInfo 포함
//
// 그 외: swapMarked

@Suite("InputStrategy 판별 테스트")
struct InputStrategyDetermineTests {

    // MARK: - swapMarked (기본값)

    @Test("빈 attributes → swapMarked")
    func testEmptyAttributes() {
        let strategy = InputStrategy.determine(from: [])
        #expect(strategy == .swapMarked)
    }

    @Test("관련 없는 attributes → swapMarked")
    func testIrrelevantAttributes() {
        let strategy = InputStrategy.determine(from: ["NSColor", "NSFont"])
        #expect(strategy == .swapMarked)
    }

    // MARK: - directInsert 조건

    @Test("NSTextAlternatives → directInsert")
    func testNSTextAlternatives() {
        let strategy = InputStrategy.determine(from: ["NSTextAlternatives"])
        #expect(strategy == .directInsert)
    }

    @Test("NSMarkedClauseSegment + NSFont → directInsert")
    func testMarkedClauseSegmentWithFont() {
        let strategy = InputStrategy.determine(from: ["NSMarkedClauseSegment", "NSFont"])
        #expect(strategy == .directInsert)
    }

    @Test("NSMarkedClauseSegment + NSGlyphInfo → directInsert")
    func testMarkedClauseSegmentWithGlyphInfo() {
        let strategy = InputStrategy.determine(from: ["NSMarkedClauseSegment", "NSGlyphInfo"])
        #expect(strategy == .directInsert)
    }

    @Test("NSTextAlternatives 포함 시 다른 항목 무관하게 directInsert")
    func testNSTextAlternativesWithOthers() {
        let strategy = InputStrategy.determine(from: ["NSColor", "NSTextAlternatives", "NSFont"])
        #expect(strategy == .directInsert)
    }

    // MARK: - 경계 조건

    @Test("NSMarkedClauseSegment 단독 → swapMarked")
    func testMarkedClauseSegmentAlone() {
        let strategy = InputStrategy.determine(from: ["NSMarkedClauseSegment"])
        #expect(strategy == .swapMarked)
    }

    @Test("NSGlyphInfo 단독 → swapMarked")
    func testGlyphInfoAlone() {
        let strategy = InputStrategy.determine(from: ["NSGlyphInfo"])
        #expect(strategy == .swapMarked)
    }

    @Test("NSFont 단독 → swapMarked")
    func testFontAlone() {
        let strategy = InputStrategy.determine(from: ["NSFont"])
        #expect(strategy == .swapMarked)
    }
}

// MARK: - 실제 클라이언트별 예상 전략 테스트
//
// 실제 앱의 validAttributesForMarkedText 반환값을 기반으로 전략이 올바르게 판별되는지 검증.
// 이 테스트는 실제 로그에서 수집한 attributes 를 기록하여 회귀를 방지한다.
//
// ⚠️ 앱 업데이트로 attributes 가 변경될 수 있으므로 주기적 확인 필요

@Suite("클라이언트별 전략 판별 테스트")
struct ClientStrategyTests {

    @Test("Chrome (com.google.Chrome) → swapMarked")
    func testChromeStrategy() {
        // Chrome 은 NSMarkedClauseSegment 를 반환하지만 NSGlyphInfo/NSFont 없음
        let chromeAttributes = ["NSMarkedClauseSegment"]
        #expect(InputStrategy.determine(from: chromeAttributes) == .swapMarked)
    }

    @Test("Spotlight 검색 → directInsert (NSTextAlternatives 포함)")
    func testSpotlightStrategy() {
        let spotlightAttributes = ["NSTextAlternatives", "NSMarkedClauseSegment", "NSFont"]
        #expect(InputStrategy.determine(from: spotlightAttributes) == .directInsert)
    }

    @Test("NSMarkedClauseSegment + NSFont + NSGlyphInfo → directInsert")
    func testRichTextClientStrategy() {
        let attributes = ["NSMarkedClauseSegment", "NSFont", "NSGlyphInfo"]
        #expect(InputStrategy.determine(from: attributes) == .directInsert)
    }
}

// MARK: - flush 경로 동작 테스트
//
// PatalInputController.inputText 의 flush 경로에서 strategy 에 따른 기대 동작을 검증.
// IMKTextInput 클라이언트를 직접 Mock 할 수 없으므로, HangulProcessor 의 flushCommit 결과를 검증.

@Suite("flush 경로 테스트", .serialized)
struct FlushPathTests {
    let layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)
    var processor: HangulProcessor!

    init() {
        processor = HangulProcessor(layout: layout)
    }

    @Test("조합 없이 flush → 빈 결과")
    func testFlushWithoutComposition() {
        let result = processor.flushCommit()
        #expect(result.isEmpty)
    }

    @Test("초성만 조합 중 flush → 초성 반환")
    func testFlushWithChosungOnly() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        let result = processor.flushCommit()
        #expect(!result.isEmpty)
        #expect(result.first == "ㄱ")
    }

    @Test("초성+중성 조합 중 flush → 완성 글자 반환")
    func testFlushWithChosungJungsung() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        processor.rawChar = "f"
        _ = processor.한글조합()
        let result = processor.flushCommit()
        #expect(!result.isEmpty)
        #expect(result.first == "가")
    }

    @Test("flush 후 재조합 가능")
    func testRecompositionAfterFlush() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        _ = processor.flushCommit()

        // flush 후 새로운 조합 시작
        processor.rawChar = "h"
        _ = processor.한글조합()
        let result = processor.flushCommit()
        #expect(result.first == "ㄴ")
    }

    @Test("flush 후 countComposable 은 0")
    func testCountComposableAfterFlush() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        #expect(processor.countComposable() > 0)

        _ = processor.flushCommit()
        #expect(processor.countComposable() == 0)
    }
}

// MARK: - 실제 측정 기반 테스트

/// 실제 앱에서 측정한 validAttributesForMarkedText 값을 기반으로 작성된 테스트
/// 측정 데이터: misc/client-attributes.md 참조
/// 최종 측정: 2026-02-05 (macOS 15.7.2 Sequoia)
@Suite("실제 클라이언트 측정 기반 테스트")
struct RealWorldMeasuredTests {

    // MARK: - 브라우저

    @Suite("웹 브라우저")
    struct BrowserTests {

        @Test("Chrome (com.google.Chrome) → swapMarked")
        func testChromeStrategy() {
            // 기존 ClientStrategyTests와 중복이지만 카테고리화를 위해 포함
            let chromeAttributes = ["NSMarkedClauseSegment"]
            #expect(InputStrategy.determine(from: chromeAttributes) == .swapMarked)
        }

        @Test("Safari (com.apple.Safari) → directInsert")
        func testSafariStrategy() {
            let attributes = ["NSFont", "NSUnderline", "NSColor", "NSBackgroundColor", "NSUnderlineColor", 
                            "NSMarkedClauseSegment", "NSLanguage", "NSTextInputReplacementRangeAttributeName", 
                            "NSTextAlternatives", "NSTextInsertionUndoable", "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .directInsert)
        }

        @Test("Firefox (org.mozilla.firefox) → swapMarked")
        func testFirefoxStrategy() {
            let attributes = ["NSUnderline", "NSUnderlineColor", "NSMarkedClauseSegment", 
                            "NSTextInputReplacementRangeAttributeName", "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .swapMarked)
        }
    }

    // MARK: - 개발 도구

    @Suite("개발 도구")
    struct DeveloperToolTests {

        @Test("Xcode (com.apple.dt.Xcode) → directInsert")
        func testXcodeStrategy() {
            let attributes = ["NSMarkedClauseSegment", "NSGlyphInfo", "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .directInsert)
        }

        @Test("Terminal.app (com.apple.Terminal) → swapMarked")
        func testTerminalStrategy() {
            let attributes = ["NSUnderline", "NSBackgroundColor", "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .swapMarked)
        }

        @Test("iTerm2 (com.googlecode.iterm2) → swapMarked")
        func testITerm2Strategy() {
            let attributes = ["NSColor", "NSBackgroundColor", "NSUnderline", "NSFont", "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .swapMarked)
        }
    }

    // MARK: - 텍스트 편집기

    @Suite("텍스트 편집기")
    struct TextEditorTests {

        @Test("TextEdit (com.apple.TextEdit) → directInsert")
        func testTextEditStrategy() {
            let attributes = ["NSFont", "NSUnderline", "NSColor", "NSBackgroundColor", "NSUnderlineColor", 
                            "NSMarkedClauseSegment", "NSLanguage", "NSTextInputReplacementRangeAttributeName", 
                            "NSGlyphInfo", "NSTextAlternatives", "NSTextInsertionUndoable", "NSAttachment", 
                            "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .directInsert)
        }

        @Test("Pages (com.apple.iWork.Pages) → directInsert")
        func testPagesStrategy() {
            let attributes = ["NSBackgroundColor", "NSUnderline", "NSUnderlineColor", "NSColor", "NSFont", 
                            "NSMarkedClauseSegment", "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .directInsert)
        }

        @Test("Notes (com.apple.Notes) → directInsert")
        func testNotesStrategy() {
            let attributes = ["NSFont", "NSUnderline", "NSColor", "NSBackgroundColor", "NSUnderlineColor", 
                            "NSMarkedClauseSegment", "NSLanguage", "NSTextInputReplacementRangeAttributeName", 
                            "NSGlyphInfo", "NSTextAlternatives", "NSTextInsertionUndoable", "NSAttachment", 
                            "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .directInsert)
        }
    }

    // MARK: - Electron 앱

    @Suite("Electron 기반 앱")
    struct ElectronAppTests {

        @Test("VS Code (com.microsoft.VSCode) → swapMarked")
        func testVSCodeStrategy() {
            // Chromium 기반이지만 Chrome보다 풍부 (5개 vs 1개)
            let attributes = ["NSUnderline", "NSUnderlineColor", "NSMarkedClauseSegment", 
                            "NSTextInputReplacementRangeAttributeName", "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .swapMarked)
        }

        @Test("Slack (com.tinyspeck.slackmacgap) → swapMarked")
        func testSlackStrategy() {
            // Firefox, VS Code, Discord와 동일
            let attributes = ["NSUnderline", "NSUnderlineColor", "NSMarkedClauseSegment", 
                            "NSTextInputReplacementRangeAttributeName", "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .swapMarked)
        }

        @Test("Discord (com.hnc.Discord) → swapMarked")
        func testDiscordStrategy() {
            // Bundle ID가 com.hnc.Discord (한글과컴퓨터 버전)
            let attributes = ["NSUnderline", "NSUnderlineColor", "NSMarkedClauseSegment", 
                            "NSTextInputReplacementRangeAttributeName", "NSDictationHiliteMarkedText"]
            #expect(InputStrategy.determine(from: attributes) == .swapMarked)
        }
    }
}
