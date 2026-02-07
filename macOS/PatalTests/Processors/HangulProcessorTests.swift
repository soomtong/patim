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

@Suite("커밋 후 백스페이스 테스트", .serialized)
struct CommittedBackspaceTests {
    let layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_P2)
    var processor: HangulProcessor!

    init() {
        processor = HangulProcessor(layout: layout)
    }

    @Test("초성+새초성 경로: 위자 → 위ㅈ → 위")
    func testChosungCommitBackspace() {
        // 신세벌P2: j(ㅇ) + o(ㅜ) + d(ㅣ) = "위"
        processor.rawChar = "j"
        var state = processor.한글조합()
        #expect(state == CommitState.composing)

        processor.rawChar = "o"
        state = processor.한글조합()
        #expect(state == CommitState.composing)

        processor.rawChar = "d"
        state = processor.한글조합()
        #expect(state == CommitState.composing)
        #expect(processor.getComposed() == "위")

        // l(초성ㅈ) + f(ㅏ) = "자" (새 글자 시작)
        processor.rawChar = "l"
        state = processor.한글조합()
        #expect(state == CommitState.committed)  // "위" 커밋
        #expect(processor.완성 == "위")
        #expect(processor.getComposed() == "ㅈ")

        processor.rawChar = "f"
        state = processor.한글조합()
        #expect(state == CommitState.composing)
        #expect(processor.getComposed() == "자")

        // 백스페이스: "자" → "ㅈ"
        var count = processor.applyBackspace()
        #expect(count == 1)
        #expect(processor.getComposed() == "ㅈ")

        // 백스페이스: "ㅈ" → 빈 상태 (이전 커밋된 "위"는 영향 없음)
        count = processor.applyBackspace()
        #expect(count == 0)
        #expect(processor.getComposed() == nil)
    }

    @Test("중성+새중성 경로: 커밋 후 백스페이스")
    func testJungsungCommitBackspace() {
        // 신세벌P2에서 중성만 입력하고 새 중성이 오는 경우
        // 모아치기 자판에서 중성으로 시작할 수 있음
        let layoutMoachigi = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)
        let proc = HangulProcessor(layout: layoutMoachigi)

        // f(ㅏ) = 중성만
        proc.rawChar = "f"
        var state = proc.한글조합()
        #expect(state == CommitState.composing)

        // g(ㅓ) = 새 중성, 이전 중성 커밋
        proc.rawChar = "g"
        state = proc.한글조합()
        #expect(state == CommitState.committed)
        #expect(proc.완성 != nil)

        // 백스페이스: 새 글자만 영향
        let count = proc.applyBackspace()
        #expect(count == 0)
        #expect(proc.getComposed() == nil)
    }

    @Test("종성+새종성 경로: 커밋 후 백스페이스")
    func testJongsungCommitBackspace() {
        // 모아치기 자판에서 종성만 입력 가능
        let layoutMoachigi = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)
        let proc = HangulProcessor(layout: layoutMoachigi)

        // x(종성ㄴ) = 종성만
        proc.rawChar = "x"
        var state = proc.한글조합()
        #expect(state == CommitState.composing)

        // z(종성ㅁ) = 새 종성 시도 (겹받침 안되면 커밋)
        proc.rawChar = "z"
        state = proc.한글조합()
        // 종성+종성이 겹받침을 이루는지에 따라 결과가 다름

        // 커밋된 경우 백스페이스 테스트
        if state == CommitState.committed {
            let count = proc.applyBackspace()
            #expect(count == 0)
            #expect(proc.getComposed() == nil)
        }
    }

    @Test("우동 → 우도 → 우ㄷ → 우 시나리오")
    func testUdongBackspaceScenario() {
        // 신세벌P2: j(ㅇ) + o(ㅜ) = "우"
        processor.rawChar = "j"
        _ = processor.한글조합()
        processor.rawChar = "o"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "우")

        // u(ㄷ) + v(ㅗ) + a(ㅇ) = "동" (새 글자)
        processor.rawChar = "u"
        let state = processor.한글조합()
        #expect(state == CommitState.committed)  // "우" 커밋
        #expect(processor.완성 == "우")
        #expect(processor.getComposed() == "ㄷ")

        processor.rawChar = "v"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "도")

        processor.rawChar = "a"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "동")

        // 백스페이스: "동" → "도"
        var count = processor.applyBackspace()
        #expect(count == 2)
        #expect(processor.getComposed() == "도")

        // 백스페이스: "도" → "ㄷ"
        count = processor.applyBackspace()
        #expect(count == 1)
        #expect(processor.getComposed() == "ㄷ")

        // 백스페이스: "ㄷ" → 빈 상태 (이전 "우"는 이미 커밋됨)
        count = processor.applyBackspace()
        #expect(count == 0)
        #expect(processor.getComposed() == nil)
        // keyHistory가 비어있어야 함 (이전 글자 키가 남아있지 않음)
        #expect(processor.keyHistory.isEmpty)
    }
}

// ESC, 화살표 키 입력 시 flushComposition 시뮬레이션
// handle(_:client:) 에서 countComposable > 0 이면 flushCommit + clearBuffers 호출
@Suite("ESC/화살표 flush 테스트", .serialized)
struct NavigationKeyFlushTests {
    let layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_P2)
    var processor: HangulProcessor!

    init() {
        processor = HangulProcessor(layout: layout)
    }

    /// flushComposition 동작 시뮬레이션
    private mutating func simulateFlush() -> [String] {
        let flushed = processor.flushCommit()
        processor.clearPreedit()
        processor.clearBuffers()
        return flushed
    }

    @Test("초성 조합 중 flush → 초성 커밋")
    mutating func testFlushDuringChosung() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        #expect(processor.countComposable() > 0)

        let flushed = simulateFlush()
        #expect(flushed == ["ㄱ"])
        #expect(processor.countComposable() == 0)
        #expect(processor.getComposed() == nil)
    }

    @Test("초성+중성 조합 중 flush → 완성 글자 커밋")
    mutating func testFlushDuringChosungJungsung() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        processor.rawChar = "f"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "가")

        let flushed = simulateFlush()
        #expect(flushed == ["가"])
        #expect(processor.countComposable() == 0)
    }

    @Test("초성+중성+종성 조합 중 flush → 완성 글자 커밋")
    mutating func testFlushDuringFullSyllable() {
        // k(ㄱ) + f(ㅏ) + a(ㅇ) = "강"
        processor.rawChar = "k"
        _ = processor.한글조합()
        processor.rawChar = "f"
        _ = processor.한글조합()
        processor.rawChar = "a"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "강")

        let flushed = simulateFlush()
        #expect(flushed == ["강"])
        #expect(processor.countComposable() == 0)
    }

    @Test("커밋 후 새 글자 조합 중 flush → 새 글자만 커밋")
    mutating func testFlushAfterCommitDuringNewComposition() {
        // j(ㅇ) + o(ㅜ) + d(ㅣ) = "위"
        processor.rawChar = "j"
        _ = processor.한글조합()
        processor.rawChar = "o"
        _ = processor.한글조합()
        processor.rawChar = "d"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "위")

        // l(ㅈ) → "위" 커밋, "ㅈ" 조합 시작
        processor.rawChar = "l"
        let state = processor.한글조합()
        #expect(state == CommitState.committed)
        #expect(processor.완성 == "위")

        // 커밋된 "위"를 소비
        processor.clearBuffers()

        // f(ㅏ) → "자" 조합 중
        processor.rawChar = "f"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "자")

        // ESC/화살표 → flush
        let flushed = simulateFlush()
        #expect(flushed == ["자"])
        #expect(processor.countComposable() == 0)
    }

    @Test("조합 없는 상태에서 flush → 빈 결과")
    mutating func testFlushWithoutComposition() {
        #expect(processor.countComposable() == 0)

        let flushed = simulateFlush()
        #expect(flushed.isEmpty)
    }

    @Test("flush 후 새로운 조합 가능")
    mutating func testNewCompositionAfterFlush() {
        // "가" 조합 후 flush
        processor.rawChar = "k"
        _ = processor.한글조합()
        processor.rawChar = "f"
        _ = processor.한글조합()

        let flushed = simulateFlush()
        #expect(flushed == ["가"])

        // flush 후 "나" 새 조합
        processor.rawChar = "h"
        _ = processor.한글조합()
        processor.rawChar = "f"
        _ = processor.한글조합()
        #expect(processor.getComposed() == "나")
        #expect(processor.countComposable() == 2)
    }
}
