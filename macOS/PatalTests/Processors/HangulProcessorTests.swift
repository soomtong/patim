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
        #expect(processor.verifyProcessable("!") == false)
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
