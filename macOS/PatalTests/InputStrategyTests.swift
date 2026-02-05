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

// MARK: - 빠른 경로 테스트 (knownApps 캐시)
//
// InputStrategy.determineFast(bundleId:)는 측정 완료된 앱에 대해
// validAttributesForMarkedText() 호출 없이 바로 전략을 반환한다.
// Sok 입력기 참고: https://github.com/kiding/SokIM/blob/main/SokIM/Strategy.swift

@Suite("빠른 경로 테스트 (knownApps)")
struct FastPathTests {

    // MARK: - determineFast 기본 테스트

    @Test("측정된 앱: Safari → directInsert")
    func testFastPathSafari() {
        let strategy = InputStrategy.determineFast(bundleId: "com.apple.Safari")
        #expect(strategy == .directInsert)
    }

    @Test("측정된 앱: Chrome → swapMarked")
    func testFastPathChrome() {
        let strategy = InputStrategy.determineFast(bundleId: "com.google.Chrome")
        #expect(strategy == .swapMarked)
    }

    @Test("측정된 앱: Xcode → directInsert")
    func testFastPathXcode() {
        let strategy = InputStrategy.determineFast(bundleId: "com.apple.dt.Xcode")
        #expect(strategy == .directInsert)
    }

    @Test("측정된 앱: VS Code → swapMarked")
    func testFastPathVSCode() {
        let strategy = InputStrategy.determineFast(bundleId: "com.microsoft.VSCode")
        #expect(strategy == .swapMarked)
    }

    @Test("미측정 앱 → nil (휴리스틱 폴백)")
    func testFastPathUnknown() {
        let strategy = InputStrategy.determineFast(bundleId: "com.example.unknown")
        #expect(strategy == nil)
    }

    // MARK: - 원래 12개 앱 검증 (Patal 측정)

    @Test("Patal 측정 12개 앱 전략 검증")
    func testPatalMeasuredApps() {
        // directInsert 앱 (5개)
        #expect(InputStrategy.determineFast(bundleId: "com.apple.Safari") == .directInsert)
        #expect(InputStrategy.determineFast(bundleId: "com.apple.dt.Xcode") == .directInsert)
        #expect(InputStrategy.determineFast(bundleId: "com.apple.TextEdit") == .directInsert)
        #expect(InputStrategy.determineFast(bundleId: "com.apple.iWork.Pages") == .directInsert)
        #expect(InputStrategy.determineFast(bundleId: "com.apple.Notes") == .directInsert)

        // swapMarked 앱 (7개)
        #expect(InputStrategy.determineFast(bundleId: "com.google.Chrome") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "org.mozilla.firefox") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.apple.Terminal") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.googlecode.iterm2") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.microsoft.VSCode") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.tinyspeck.slackmacgap") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.hnc.Discord") == .swapMarked)
    }

    // MARK: - Sok 입력기 참고 추가 앱

    @Test("Sok 참고: iWork 앱")
    func testSokIWorkApps() {
        #expect(InputStrategy.determineFast(bundleId: "com.apple.iWork.Pages") == .directInsert)
        #expect(InputStrategy.determineFast(bundleId: "com.apple.iWork.Keynote") == .directInsert)
        // Numbers는 overrideApps에서 처리 (아래 테스트)
    }

    @Test("Sok 참고: Microsoft Office 앱")
    func testSokMicrosoftOffice() {
        #expect(InputStrategy.determineFast(bundleId: "com.microsoft.Word") == .directInsert)
        #expect(InputStrategy.determineFast(bundleId: "com.microsoft.Powerpoint") == .directInsert)
        #expect(InputStrategy.determineFast(bundleId: "com.microsoft.Excel") == .swapMarked)
    }

    @Test("Sok 참고: 개발 도구")
    func testSokDevTools() {
        #expect(InputStrategy.determineFast(bundleId: "io.alacritty") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.google.android.studio") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.sublimetext.4") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.sublimetext.3") == .swapMarked)
    }

    @Test("Sok 참고: 기타 앱")
    func testSokOtherApps() {
        #expect(InputStrategy.determineFast(bundleId: "com.apple.Stickies") == .directInsert)
        #expect(InputStrategy.determineFast(bundleId: "com.duckduckgo.macos.browser") == .directInsert)
        #expect(InputStrategy.determineFast(bundleId: "jp.naver.line.mac") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "org.gimp.gimp-2.10") == .swapMarked)
    }
}

// MARK: - 오버라이드 테스트 (휴리스틱과 반대로 작동하는 앱)
//
// Numbers는 NSFont + NSMarkedClauseSegment를 반환하지만 swapMarked가 필요
// Sok 입력기에서 발견된 예외 케이스

@Suite("오버라이드 테스트")
struct OverrideTests {

    @Test("Numbers: 휴리스틱과 반대 (directInsert 조건이지만 swapMarked)")
    func testNumbersOverride() {
        // Numbers는 NSFont + NSMarkedClauseSegment를 반환하지만 swapMarked 필요
        let strategy = InputStrategy.determineFast(bundleId: "com.apple.iWork.Numbers")
        #expect(strategy == .swapMarked)
    }

    @Test("Numbers: attributes와 무관하게 오버라이드")
    func testNumbersIgnoresAttributes() {
        // 휴리스틱으로는 directInsert가 되어야 하는 조건
        let attributes = ["NSFont", "NSMarkedClauseSegment", "NSTextAlternatives"]
        let strategy = InputStrategy.determine(bundleId: "com.apple.iWork.Numbers", attributes: attributes)
        #expect(strategy == .swapMarked)  // 오버라이드로 swapMarked
    }
}

// MARK: - Prefix 매칭 테스트 (한컴오피스 등)
//
// 한컴오피스는 한글, 한셀, 한쇼 등 여러 앱이 있으며
// 모두 com.hancom.office.hwp prefix를 공유

@Suite("Prefix 매칭 테스트")
struct PrefixMatchTests {

    @Test("한컴오피스 한글 → swapMarked")
    func testHancomHangul() {
        let strategy = InputStrategy.determineFast(bundleId: "com.hancom.office.hwp.mac")
        #expect(strategy == .swapMarked)
    }

    @Test("한컴오피스 한셀 → swapMarked")
    func testHancomHancel() {
        let strategy = InputStrategy.determineFast(bundleId: "com.hancom.office.hwp.hancel")
        #expect(strategy == .swapMarked)
    }

    @Test("한컴오피스 한쇼 → swapMarked")
    func testHancomHanshow() {
        let strategy = InputStrategy.determineFast(bundleId: "com.hancom.office.hwp.hanshow")
        #expect(strategy == .swapMarked)
    }

    @Test("한컴오피스 prefix 일치")
    func testHancomPrefix() {
        // 다양한 한컴오피스 변형
        #expect(InputStrategy.determineFast(bundleId: "com.hancom.office.hwp") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.hancom.office.hwp.2020") == .swapMarked)
        #expect(InputStrategy.determineFast(bundleId: "com.hancom.office.hwp.mac.v2") == .swapMarked)
    }

    @Test("한컴오피스가 아닌 앱은 prefix 매칭 안 됨")
    func testNonHancom() {
        // com.hancom으로 시작하지만 hwp가 아닌 경우
        let strategy = InputStrategy.determineFast(bundleId: "com.hancom.other.app")
        #expect(strategy == nil)  // 캐시에 없으므로 nil
    }
}

// MARK: - 하이브리드 API 테스트
//
// InputStrategy.determine(bundleId:attributes:)는 측정된 앱은 캐시에서,
// 미측정 앱은 휴리스틱으로 전략을 결정한다.

@Suite("하이브리드 API 테스트")
struct HybridApiTests {

    @Test("미측정 앱: 휴리스틱 결과 유지")
    func testHybridApiDefaultBehavior() {
        // 미측정 앱은 휴리스틱 결과 사용
        let attributes = ["NSMarkedClauseSegment"]
        let strategy = InputStrategy.determine(bundleId: "com.example.unknown", attributes: attributes)
        #expect(strategy == .swapMarked)
    }

    @Test("미측정 앱: NSTextAlternatives 포함 시 directInsert")
    func testHybridApiWithTextAlternatives() {
        let attributes = ["NSTextAlternatives", "NSMarkedClauseSegment"]
        let strategy = InputStrategy.determine(bundleId: "com.example.app", attributes: attributes)
        #expect(strategy == .directInsert)
    }

    @Test("미측정 앱: 빈 attributes → swapMarked")
    func testHybridApiEmptyAttributes() {
        let strategy = InputStrategy.determine(bundleId: "com.example.unknown", attributes: [])
        #expect(strategy == .swapMarked)
    }

    // MARK: - 측정된 앱은 attributes 무시

    @Test("측정된 앱: attributes와 무관하게 캐시 결과 반환")
    func testKnownAppIgnoresAttributes() {
        // Chrome은 swapMarked로 측정됨
        // NSTextAlternatives를 전달해도 캐시된 swapMarked 반환
        let attributes = ["NSTextAlternatives", "NSMarkedClauseSegment"]
        let strategy = InputStrategy.determine(bundleId: "com.google.Chrome", attributes: attributes)
        #expect(strategy == .swapMarked)
    }

    @Test("측정된 앱: 빈 attributes도 캐시 결과 반환")
    func testKnownAppWithEmptyAttributes() {
        // Safari는 directInsert로 측정됨
        let strategy = InputStrategy.determine(bundleId: "com.apple.Safari", attributes: [])
        #expect(strategy == .directInsert)
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
