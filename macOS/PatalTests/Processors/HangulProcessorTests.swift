//
//  HangulProcessorTests.swift
//  PatalTests
//
//  Created by dp on 12/26/24.
//

import Testing

@testable import Patal

@Suite("입력기 처리 테스트", .serialized)
struct HangulProcessorTests {
    let layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)
    var processor: HangulProcessor!

    init() {
        processor = HangulProcessor(layout: layout)
    }

    @Test("Verify Processable Characters")
    func testVerifyProcessable() {
        #expect(processor.verifyProcessable("k") == true)
        #expect(processor.verifyProcessable("f") == true)
        #expect(processor.verifyProcessable("!", keyCode: 18, modifierCode: 131072) == false)
    }

    @Test("Verify Combosable Characters")
    func testVerifyCombosable() {
        #expect(processor.verifyCombosable("k") == true)
        #expect(processor.verifyCombosable("f") == true)
        #expect(processor.verifyCombosable("!") == false)
    }

    @Test("Hangul Composition")
    func testHangulComposition() {
        processor.rawChar = "k"
        var state = processor.한글조합()
        #expect(state == CommitState.composing)
        #expect(processor.getComposed() == "ㄱ")  // ᄀ

        processor.rawChar = "k"
        state = processor.한글조합()
        #expect(state == CommitState.composing)
        #expect(processor.getComposed() == "ㄲ")  // ᄁ

        processor.rawChar = "f"
        state = processor.한글조합()
        #expect(state == CommitState.composing)
        #expect(processor.getComposed() == "까")  // 까

        processor.rawChar = "a"
        state = processor.한글조합()
        #expect(state == CommitState.composing)
        #expect(processor.getComposed() == "깡")  // 깡
    }

    @Test("Non-Hangul Composition")
    func testNonHangulComposition() {
        processor.rawChar = "!"
        #expect(processor.getComposed() == nil)
        #expect(processor.getConverted() == nil)
    }

    @Test("Flush Commit")
    func testFlushCommit() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "ㄱ")
        let buffers = processor.flushCommit()
        #expect(buffers.count == 1)
    }

    @Test("백스페이스 처리 - 키 히스토리 기반")
    func testBackspace() {
        // "감" 입력: k(ㄱ) + f(ㅏ) + z(ㅁ)
        processor.rawChar = "k"
        _ = processor.한글조합()
        processor.rawChar = "f"
        _ = processor.한글조합()
        processor.rawChar = "z"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "감")

        // 종성 삭제 -> "가"
        var composableCount = processor.applyBackspace()
        #expect(composableCount == 2)
        #expect(processor.preedit.chosung != nil)
        #expect(processor.preedit.jungsung != nil)
        #expect(processor.preedit.jongsung == nil)
        #expect(processor.getComposed() == "가")

        // 중성 삭제 -> "ㄱ"
        composableCount = processor.applyBackspace()
        #expect(composableCount == 1)
        #expect(processor.preedit.chosung != nil)
        #expect(processor.preedit.jungsung == nil)
        #expect(processor.getComposed() == "ㄱ")

        // 초성 삭제 -> 빈 상태
        composableCount = processor.applyBackspace()
        #expect(composableCount == 0)
        #expect(processor.preedit.chosung == nil)
        #expect(processor.preedit.jungsung == nil)
        #expect(processor.preedit.jongsung == nil)
        #expect(processor.getComposed() == nil)
    }

    @Test("백스페이스 처리 - 초성")
    func testBackspace1() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        let composableCount = processor.applyBackspace()
        #expect(composableCount == 0)
        #expect(processor.preedit.chosung == nil)
        #expect(processor.getComposed() == nil)
    }

    @Test("백스페이스 처리 - 중성")
    func testBackspace2() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        let c1 = processor.getComposed()
        #expect(c1 == "ㄱ")
        processor.rawChar = "f"
        _ = processor.한글조합()
        let c2 = processor.getComposed()
        #expect(c2 == "가")
        let composableCount = processor.applyBackspace()
        #expect(composableCount == 1)
        #expect(processor.preedit.chosung != nil)
        #expect(processor.preedit.jungsung == nil)
        #expect(processor.getComposed() == "ㄱ")
    }

    @Test("백스페이스 처리 - 종성")
    func testBackspace3() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        let c1 = processor.getComposed()
        #expect(c1 == "ㄱ")
        processor.rawChar = "f"
        _ = processor.한글조합()
        let c2 = processor.getComposed()
        #expect(c2 == "가")
        processor.rawChar = "a"
        _ = processor.한글조합()
        let c3 = processor.getComposed()
        #expect(c3 == "강")
        let composableCount = processor.applyBackspace()
        #expect(composableCount == 2)
        #expect(processor.preedit.chosung != nil)
        #expect(processor.preedit.jungsung != nil)
        #expect(processor.preedit.jongsung == nil)
        #expect(processor.getComposed() == "가")
    }

    @Test("Clear Preedit")
    func testClearPreedit() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        processor.clearPreedit()
        #expect(processor.getComposed() == nil)
    }

    @Test("Get Converted Character")
    func testGetConverted() {
        processor.rawChar = "L"
        #expect(processor.getConverted() == ".")
    }
}

@Suite("겹모음 백스페이스 테스트", .serialized)
struct DoubleVowelBackspaceTests {
    let layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_P2)
    var processor: HangulProcessor!

    init() {
        processor = HangulProcessor(layout: layout)
    }

    @Test("겹모음 '위' 백스페이스: 위 → 우 → ㅇ")
    func testDoubleVowelBackspace_Wi() {
        // 신세벌P2: j(ㅇ) + o(ㅜ) + d(ㅣ) = "위"
        processor.rawChar = "j"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "ㅇ")

        processor.rawChar = "o"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "우")

        processor.rawChar = "d"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "위")

        // 백스페이스: "위" → "우"
        var count = processor.applyBackspace()
        #expect(count == 2)
        #expect(processor.getComposed() == "우")

        // 백스페이스: "우" → "ㅇ"
        count = processor.applyBackspace()
        #expect(count == 1)
        #expect(processor.getComposed() == "ㅇ")

        // 백스페이스: "ㅇ" → 빈 상태
        count = processor.applyBackspace()
        #expect(count == 0)
        #expect(processor.getComposed() == nil)
    }

    @Test("겹모음 '워' 백스페이스: 워 → 우 → ㅇ")
    func testDoubleVowelBackspace_Wo() {
        // 신세벌P2: j(ㅇ) + o(ㅜ) + r(ㅓ) = "워"
        processor.rawChar = "j"
        _ = processor.한글조합()

        processor.rawChar = "o"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "우")

        processor.rawChar = "r"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "워")

        // 백스페이스: "워" → "우"
        var count = processor.applyBackspace()
        #expect(count == 2)
        #expect(processor.getComposed() == "우")

        // 백스페이스: "우" → "ㅇ"
        count = processor.applyBackspace()
        #expect(count == 1)
        #expect(processor.getComposed() == "ㅇ")
    }

    @Test("겹초성 백스페이스: 까 → ㄲ → ㄱ")
    func testDoubleChosungBackspace() {
        // 신세벌P2: k(ㄱ) + k(ㄲ) + f(ㅏ) = "까"
        processor.rawChar = "k"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "ㄱ")

        processor.rawChar = "k"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "ㄲ")

        processor.rawChar = "f"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "까")

        // 백스페이스: "까" → "ㄲ"
        var count = processor.applyBackspace()
        #expect(count == 1)
        #expect(processor.getComposed() == "ㄲ")

        // 백스페이스: "ㄲ" → "ㄱ"
        count = processor.applyBackspace()
        #expect(count == 1)
        #expect(processor.getComposed() == "ㄱ")

        // 백스페이스: "ㄱ" → 빈 상태
        count = processor.applyBackspace()
        #expect(count == 0)
        #expect(processor.getComposed() == nil)
    }

    @Test("겹종성 백스페이스: 닭 → 달 → 다 → ㄷ")
    func testDoubleJongsungBackspace() {
        // 신세벌P2: u(ㄷ) + f(ㅏ) + w(ㄹ) + c(ㄱ) = "닭"
        processor.rawChar = "u"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "ㄷ")

        processor.rawChar = "f"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "다")

        processor.rawChar = "w"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "달")

        processor.rawChar = "c"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "닭")

        // 백스페이스: "닭" → "달"
        var count = processor.applyBackspace()
        #expect(count == 3)
        #expect(processor.getComposed() == "달")

        // 백스페이스: "달" → "다"
        count = processor.applyBackspace()
        #expect(count == 2)
        #expect(processor.getComposed() == "다")

        // 백스페이스: "다" → "ㄷ"
        count = processor.applyBackspace()
        #expect(count == 1)
        #expect(processor.getComposed() == "ㄷ")
    }

    @Test("종성 삭제 후 수정: 분 → 부 → 북")
    func testJongsungDeleteAndReplace_분북() {
        // 신세벌P2: ;(ㅂ) + b(ㅜ) + s(ㄴ) = "분"
        processor.rawChar = ";"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "ㅂ")

        processor.rawChar = "b"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "부")

        processor.rawChar = "s"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "분")

        // 백스페이스: "분" → "부"
        let count = processor.applyBackspace()
        #expect(count == 2)
        #expect(processor.getComposed() == "부")

        // 새 종성 추가: "부" + c(ㄱ) = "북"
        processor.rawChar = "c"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "북")
    }

    @Test("종성/중성 삭제 후 재입력: 복 → 보 → ㅂ → 부 → 북")
    func testJongsungJungsungDeleteAndReplace_복북() {
        // 신세벌P2: ;(ㅂ) + v(ㅗ) + c(ㄱ) = "복"
        processor.rawChar = ";"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "ㅂ")

        processor.rawChar = "v"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "보")

        processor.rawChar = "c"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "복")

        // 백스페이스: "복" → "보"
        var count = processor.applyBackspace()
        #expect(count == 2)
        #expect(processor.getComposed() == "보")

        // 백스페이스: "보" → "ㅂ"
        count = processor.applyBackspace()
        #expect(count == 1)
        #expect(processor.getComposed() == "ㅂ")

        // 새 중성 추가: "ㅂ" + b(ㅜ) = "부"
        processor.rawChar = "b"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "부")

        // 새 종성 추가: "부" + c(ㄱ) = "북"
        processor.rawChar = "c"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "북")
    }

    @Test("종성 삭제 후 다른 종성: 웆 → 우 → 웇")
    func testJongsungReplace_웆웇() {
        // 신세벌P2: j(ㅇ) + o(ㅜ) + v(ㅈ) = "웆"
        processor.rawChar = "j"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "ㅇ")

        processor.rawChar = "o"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "우")

        processor.rawChar = "v"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "웆")

        // 백스페이스: "웆" → "우"
        let count = processor.applyBackspace()
        #expect(count == 2)
        #expect(processor.getComposed() == "우")

        // 새 종성 추가: "우" + b(ㅊ) = "웇"
        processor.rawChar = "b"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "웇")
    }
}
