//
//  KeyProcessorTests.swift
//  PatalTests
//
//  Created by dp on 11/23/24.
//

import Testing

@testable import Patal

@Suite("신세벌 커스텀 처리기 테스트", .serialized)
struct KeyProcessorTests {
    @Test()
    func setKey() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.setKey(string: "i")
        #expect(processor.rawChar == "i")
        #expect(processor.previous == [])
    }

    @Test("가")
    func getComposedChar_가() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")
        
        processor.setKey(string: "k")
        if let (state1, test1) = processor.getComposedChar() {
            #expect(state1 == .composing)
            #expect(test1.hash == "ᄀ".hash)
            #expect(processor.preedit.count == 1)
        }
        
        processor.setKey(string: "f")
        if let (state2, test2) = processor.getComposedChar() {
            #expect(state2 == .composing)
            #expect(test2.hash == "가".hash)
            #expect(processor.preedit.count == 2)
        }
    }
    
    @Test("강")
    func getComposedChar_강() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.setKey(string: "k")
        if let (state1, test1) = processor.getComposedChar() {
            #expect(state1 == .composing)
            #expect(test1.hash == "ᄀ".hash)
            #expect(processor.preedit.count == 1)
        }

        processor.setKey(string: "f")
        if let (state2, test2) = processor.getComposedChar() {
            #expect(state2 == .composing)
            #expect(test2.hash == "가".hash)
            #expect(processor.preedit.count == 2)
        }
        
        processor.setKey(string: "a")
        if let (state3, test3) = processor.getComposedChar() {
            #expect(state3 == .none)
            #expect(test3 == "강")
            #expect(processor.preedit.isEmpty)
        }
    }
    
    @Test("강남")
    func getComposedChar_강남() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")
        
        processor.setKey(string: "k")
        if let (state1, test1) = processor.getComposedChar() {
            #expect(state1 == .composing)
            #expect(test1.hash == "ᄀ".hash)
            #expect(processor.preedit.count == 1)
        }
        
        processor.setKey(string: "f")
        if let (state2, test2) = processor.getComposedChar() {
            #expect(state2 == .composing)
            #expect(test2.hash == "가".hash)
            #expect(processor.preedit.count == 2)
        }
        
        processor.setKey(string: "a")
        if let (state3, test3) = processor.getComposedChar() {
            #expect(state3 == .none)
            #expect(test3 == "강")
            #expect(processor.preedit.isEmpty)
        }
        
        processor.setKey(string: "h")
        if let (state4, test4) = processor.getComposedChar() {
            #expect(state4 == .composing)
            #expect(test4.hash == "ᄂ".hash)
            #expect(processor.preedit.count == 1)
        }
        
        processor.setKey(string: "f")
        if let (state5, test5) = processor.getComposedChar() {
            #expect(state5 == .composing)
            #expect(test5.hash == "나".hash)
            #expect(processor.preedit.count == 2)
        }
        
        processor.setKey(string: "z")
        if let (state6, test6) = processor.getComposedChar() {
            #expect(state6 == .none)
            #expect(test6 == "남")
            #expect(processor.preedit.isEmpty)
        }
    }
    
}
