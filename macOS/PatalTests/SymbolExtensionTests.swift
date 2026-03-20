//
//  SymbolExtensionTests.swift
//  PatalTests
//
//  Created by dp on 3/20/26.
//

import Testing

@testable import Patal

/// 테스트용 기호 맵 (신세벌)
private let shinSymbolMap: [String: [String: String]] = [
    "k": [
        "g": "…",
        "f": "·",
        "G": "♣",
    ],
    "l": [
        "g": "★",
    ],
    ";": [
        "g": "♠",
    ],
]

/// 테스트용 기호 맵 (공세벌)
private let p3SymbolMap: [String: [String: String]] = [
    "/": [
        "f": "·",
        "g": "…",
        "F": "♠",
    ],
    "9": [
        "s": "□",
    ],
]

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
        // 기호확장 trait 없음
        #expect(layout.symbolExtensionConfig == nil)
        #expect(layout.can기호확장 == false)

        layout.traits.insert(.기호확장)
        #expect(layout.can기호확장 == true)
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
        // j(ㅇ)
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "j"))

        // f(ㅏ) → 정상 한글: 아
        processor.rawChar = "f"
        let result = processor.handleSymbolExtension()
        #expect(result == nil)  // 기호 확장이 처리하지 않음
        #expect(processor.symbolState == .inactive)

        // 정상 한글 조합 계속
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.getComposed() == "아")
    }

    @Test("j → j (ㅇ+ㅇ) → 트리거 후 비단선택 초성 → inactive")
    func testTriggerThenNonLayerChosung() {
        // j(ㅇ) → triggered
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "j"))

        // h(ㄴ) → 단 선택 키가 아님 → inactive
        processor.rawChar = "h"
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

    @Test("resetSymbolState 동작")
    func testResetSymbolState() {
        processor.rawChar = "j"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "j"))

        processor.resetSymbolState()
        #expect(processor.symbolState == .inactive)
    }

    @Test("기호확장 비활성 시 triggered 되지 않음")
    func testNoTriggerWhenDisabled() {
        var layout = Han3ShinP2Layout()
        // 기호확장 trait 없음
        let proc = HangulProcessor(layout: layout)
        proc.rawChar = "j"
        _ = proc.한글조합WithSymbolCheck()
        #expect(proc.symbolState == .inactive)
        #expect(proc.getComposed() == "ㅇ")
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
        #expect(processor.getComposed() != nil)  // ㅗ
    }

    @Test("트리거: 9(ㅜ) 입력 후 triggered 상태")
    func testTrigger9() {
        processor.rawChar = "9"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "9"))
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
        // k(ㄱ) → initialConsonant
        processor.rawChar = "k"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .inactive)

        // /(ㅗ) → consonantVowel(고) → triggerState(.vowelOnly) 불일치 → 트리거 안됨
        processor.rawChar = "/"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .inactive)
        #expect(processor.getComposed() == "고")
    }

    @Test("/ 후 겹모음 /f → ㅘ, 기호확장 발동 안됨")
    func testCompoundVowelNotTrigger() {
        // /(ㅗ) → triggered
        processor.rawChar = "/"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "/"))

        // f(ㅏ) → 단 선택 키가 아님 → inactive, 정상 겹모음
        processor.rawChar = "f"
        let result = processor.handleSymbolExtension()
        #expect(result == nil)
        #expect(processor.symbolState == .inactive)

        // 정상 한글 조합: ㅗ+ㅏ=ㅘ
        _ = processor.한글조합WithSymbolCheck()
    }

    @Test("모아주기+기호확장 공존: / → k → 정상 한글 고")
    func testMoachigiCoexistence() {
        // 모아주기 활성화
        processor.hangulLayout.traits.insert(.모아주기)

        // /(ㅗ) → vowelOnly, triggered
        processor.rawChar = "/"
        _ = processor.한글조합WithSymbolCheck()
        #expect(processor.symbolState == .triggered(triggerKey: "/"))

        // k는 layerKey가 아님 → inactive, 정상 한글 조합 계속
        processor.rawChar = "k"
        let result = processor.handleSymbolExtension()
        #expect(result == nil)
        #expect(processor.symbolState == .inactive)
    }
}
