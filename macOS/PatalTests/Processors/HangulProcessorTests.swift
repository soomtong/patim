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

    @Test("백스페이스 처리")
    func testBackspace() {
        processor.preedit.chosung = 초성.기역
        processor.doBackspace()
        #expect(processor.preedit.chosung == nil)
        #expect(processor.getComposed() == nil)

        processor.preedit.chosung = 초성.기역
        processor.preedit.jungsung = 중성.아
        processor.doBackspace()
        #expect(processor.preedit.chosung != nil)
        #expect(processor.preedit.jungsung == nil)
        #expect(processor.getComposed() == "ㄱ")

        processor.preedit.chosung = 초성.기역
        processor.preedit.jungsung = 중성.아
        processor.preedit.jongsung = 종성.미음
        processor.doBackspace()
        #expect(processor.preedit.chosung != nil)
        #expect(processor.preedit.jungsung != nil)
        #expect(processor.preedit.jongsung == nil)
        #expect(processor.getComposed() == "가")

        processor.doBackspace()
        #expect(processor.preedit.chosung != nil)
        #expect(processor.preedit.jungsung == nil)
        #expect(processor.preedit.jongsung == nil)
        #expect(processor.getComposed() == "ㄱ")

        processor.doBackspace()
        print(processor.previous)
        #expect(processor.preedit.chosung == nil)
        #expect(processor.preedit.jungsung == nil)
        #expect(processor.preedit.jongsung == nil)
        #expect(processor.getComposed() == nil)
    }

    @Test("백스페이스 처리 - 초성")
    func testBackspace1() {
        processor.rawChar = "k"
        _ = processor.한글조합()
        processor.doBackspace()
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
        processor.doBackspace()
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
        processor.doBackspace()
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
