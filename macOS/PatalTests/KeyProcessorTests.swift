//
//  KeyProcessorTests.swift
//  PatalTests
//
//  Created by dp on 11/23/24.
//

import Testing

@testable import Patal

@Suite("신세벌 커스텀 처리기 테스트")
struct KeyProcessorTests {
    @Test()
    func setKey() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.setKey(string: "i", keyCode: 34, flags: 0)
        #expect(processor.string == "i")
        #expect(processor.keyCode == 34)
        #expect(processor.flags == 0)
    }

    @Test()
    func getComposedChar1() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.setKey(string: "k", keyCode: 40, flags: 0)
        if let (state1, test1) = processor.getComposedChar() {
            #expect(state1 == .composing)
            #expect(test1 == "ㄱ")
        }

        processor.setKey(string: "f", keyCode: 3, flags: 0)
        if let (state2, test2) = processor.getComposedChar() {
            #expect(state2 == .composing)
            #expect(test2 == "ㅏ")
        }
    }
}
