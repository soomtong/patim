//
//  SymbolExtensionTests.swift
//  PatalTests
//
//  Created by dp on 3/20/26.
//

import Testing

@testable import Patal

@Suite("기호 확장 테스트 - 신세벌 P2", .serialized)
struct SymbolExtensionShinP2Tests {
    var processor: HangulProcessor!

    init() {
        var layout = Han3ShinP2Layout()
        layout.traits.insert(.기호확장)
        processor = HangulProcessor(layout: layout)
    }

    @Test("기호확장 trait OFF이면 symbolExtensionConfig == nil")
    func testTraitOff() {
        var layout = Han3ShinP2Layout()
        #expect(layout.symbolExtensionConfig == nil)
        #expect(layout.can기호확장 == false)

        layout.traits.insert(.기호확장)
        #expect(layout.can기호확장 == true)
        #expect(layout.symbolExtensionConfig != nil)
    }

    @Test("SymbolExtensionState 기본 상태는 inactive")
    func testInitialState() {
        #expect(processor.symbolState == .inactive)
    }

    @Test("트리거: j(ㅇ) 입력 후 triggered 상태")
    func testTrigger() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "j"))
        #expect(processor.getComposed() == "ㅇ")
    }

    @Test("트리거 후 모음 입력 → inactive로 복귀, 정상 한글 조합")
    func testTriggerThenVowel() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "j"))

        // f(ㅏ) → P2의 symbolMap["j"]에 없으므로 직접조회 nil,
        // f는 layerKey["k","l",";"]도 아님 → inactive
        processor.rawChar = "f"
        let result = processor.handleSymbolExtension()
        #expect(result == nil)
        #expect(processor.symbolState == .inactive)

        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.getComposed() == "아")
    }

    @Test("j → k → f → 가운뎃점(·) 전체 플로우")
    func testFullSymbolFlow() {
        // j(ㅇ) → triggered
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "j"))

        // k → layerSelected("k")
        processor.rawChar = "k"
        let layerResult = processor.handleSymbolExtension()
        #expect(layerResult == "")  // 빈 문자열 = 키 소비됨
        #expect(processor.symbolState == .layerSelected(layerKey: "k"))

        // f → 가운뎃점
        processor.rawChar = "f"
        let symbolResult = processor.handleSymbolExtension()
        #expect(symbolResult == "\u{00B7}")  // ·
        #expect(processor.symbolState == .inactive)
    }

    @Test("j → k → g → 말줄임표(…)")
    func testEllipsis() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "k"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "g"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{2026}")  // …
    }

    @Test("j → l → j → 여는 작은따옴표(')")
    func testOpenSingleQuote() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "l"
        _ = processor.handleSymbolExtension()
        #expect(processor.symbolState == .layerSelected(layerKey: "l"))

        processor.rawChar = "j"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{2018}")  // '
    }

    @Test("j → ; → j → 여는 큰따옴표")
    func testOpenDoubleQuote() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = ";"
        _ = processor.handleSymbolExtension()
        #expect(processor.symbolState == .layerSelected(layerKey: ";"))

        processor.rawChar = "j"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{201C}")  // "
    }

    @Test("j → k → Shift+! → 로마숫자 Ⅰ (4단)")
    func testRomanNumeral() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "k"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "!"  // Shift+1
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{2160}")  // Ⅰ
    }

    @Test("j → k → Shift+A → 그리스문자 α (4단)")
    func testGreekAlpha() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "k"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "A"  // Shift+a
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{03B1}")  // α
    }

    @Test("j → l → 1 → 동그라미 숫자 ①")
    func testCircledNumber() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "l"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "1"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{2460}")  // ①
    }

    @Test("j → ; → d → 검은 동그라미 ●")
    func testFilledCircle() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = ";"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "d"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{25CF}")  // ●
    }

    @Test("기호 맵에 없는 키 → nil, inactive")
    func testUnmappedKey() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "k"
        _ = processor.handleSymbolExtension()
        #expect(processor.symbolState == .layerSelected(layerKey: "k"))

        // 매핑되지 않은 키
        processor.rawChar = "}"
        let result = processor.handleSymbolExtension()
        #expect(result == nil)
        #expect(processor.symbolState == .inactive)
    }

    @Test("flushCommit 시 symbolState 리셋")
    func testFlushResetsSymbolState() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "j"))

        _ = processor.flushCommit()
        #expect(processor.symbolState == .inactive)
    }

    @Test("기호확장 비활성 시 triggered 되지 않음")
    func testNoTriggerWhenDisabled() {
        let layout = Han3ShinP2Layout()
        let proc = HangulProcessor(layout: layout)
        proc.rawChar = "j"
        _ = proc.한글조합WithSymbolCheck()
        #expect(proc.symbolState == .inactive)
        #expect(proc.getComposed() == "ㅇ")
    }

    @Test("j → ; → 1 → 동그라미 숫자 ⑪ (3단)")
    func testCircledNumber11() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = ";"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "1"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{246A}")  // ⑪
    }

    @Test("j → ; → $ → 위첨자 ⁴ (6단)")
    func testSuperscript4() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = ";"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "$"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{2074}")  // ⁴
    }

    @Test("j → l → Q → 원소기호 ∈ (5단)")
    func testElementOf() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "l"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "Q"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{2208}")  // ∈
    }

    @Test("j → k → [ → 【 (1단)")
    func testBlackBracket() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "k"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "["
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{3010}")  // 【
    }

    @Test("백스페이스: layerSelected → triggered 복귀")
    func testBackspaceFromLayerSelected() {
        // j → k → layerSelected
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        processor.rawChar = "k"
        _ = processor.handleSymbolExtension()
        #expect(processor.symbolState == .layerSelected(layerKey: "k"))

        // 백스페이스 → triggered 복귀, preedit에 ㅇ
        let consumed = processor.handleSymbolBackspace()
        #expect(consumed == true)
        #expect(processor.symbolState == .triggered(triggerKey: "j"))
        #expect(processor.getComposed() == "ㅇ")
    }

    @Test("백스페이스: triggered → inactive")
    func testBackspaceFromTriggered() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "j"))

        let consumed = processor.handleSymbolBackspace()
        #expect(consumed == false)  // 기존 백스페이스에 위임
        #expect(processor.symbolState == .inactive)
    }
}

@Suite("기호 확장 테스트 - 공세벌 P3", .serialized)
struct SymbolExtensionP3Tests {
    var processor: HangulProcessor!

    init() {
        var layout = Han3P3Layout()
        layout.traits.insert(.기호확장)
        processor = HangulProcessor(layout: layout)
    }

    @Test("트리거: /(ㅗ) 입력 후 triggered 상태")
    func testTriggerSlash() {
        processor.rawChar = "/"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "/"))
    }

    @Test("트리거: 9(ㅜ) 입력 후 triggered 상태")
    func testTrigger9() {
        processor.rawChar = "9"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "9"))
    }

    @Test("2단계 직접 조회: / → f → 가운뎃점(·)")
    func testDirectSymbol() {
        processor.rawChar = "/"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "/"))

        processor.rawChar = "f"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{00B7}")  // ·
        #expect(processor.symbolState == .inactive)
    }

    @Test("2단계 직접 조회: 9 → s → 네모(□)")
    func testDirectSymbol9() {
        processor.rawChar = "9"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "s"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{25A1}")  // □
    }

    @Test("왼쪽 ㅗ(v)는 트리거하지 않음")
    func testLeftVowelNotTrigger() {
        processor.rawChar = "v"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .inactive)
    }

    @Test("왼쪽 ㅜ(b)는 트리거하지 않음")
    func testLeftUNotTrigger() {
        processor.rawChar = "b"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .inactive)
    }

    @Test("초성 뒤 / → consonantVowel 상태이므로 트리거 안됨")
    func testNoTriggerAfterChosung() {
        processor.rawChar = "k"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .inactive)

        processor.rawChar = "/"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .inactive)
        #expect(processor.getComposed() == "고")
    }

    @Test("/ 후 매핑 없는 키 → inactive, 정상 한글 계속")
    func testUnmappedKeyFallback() {
        processor.rawChar = "/"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "/"))

        // "7"은 symbolMap["/"]에 없고, layerKeys도 비어있음 → inactive
        processor.rawChar = "7"
        let result = processor.handleSymbolExtension()
        #expect(result == nil)
        #expect(processor.symbolState == .inactive)
    }

    @Test("2단계 직접 조회: / → q → 왼쪽화살표(←)")
    func testDirectArrow() {
        processor.rawChar = "/"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "q"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{2190}")  // ←
    }

    @Test("2단계 직접 조회: 9 → m → 동그라미 ①")
    func testCircledNumber9() {
        processor.rawChar = "9"
        _ = processor.한글조합WithSymbolCheck()

        processor.rawChar = "m"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{2460}")  // ①
    }

    @Test("/ 후 겹모음 키(f=ㅏ) → 기호 출력 (기호확장 우선)")
    func testSymbolOverridesCompoundVowel() {
        // 기호확장 활성 시 / + f → · (기호), ㅘ가 아님
        processor.rawChar = "/"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "/"))

        // f가 symbolMap["/"]에 있으므로 기호 출력
        processor.rawChar = "f"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{00B7}")  // · (겹모음 ㅘ 대신 가운뎃점)
    }
}

@Suite("기호 확장 테스트 - PCS", .serialized)
struct SymbolExtensionPcsTests {
    var processor: HangulProcessor!

    init() {
        var layout = Han3ShinPcsLayout()
        layout.traits.insert(.기호확장)
        processor = HangulProcessor(layout: layout)
    }

    @Test("PCS도 P2와 동일한 기호 맵 사용")
    func testSharedSymbolMap() {
        // j → k → f → 가운뎃점
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "j"))

        processor.rawChar = "k"
        _ = processor.handleSymbolExtension()

        processor.rawChar = "f"
        let result = processor.handleSymbolExtension()
        #expect(result == "\u{00B7}")  // ·
    }
}
