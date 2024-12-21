//
//  KeyProcessorTests.swift
//  PatalTests
//
//  Created by dp on 11/23/24.
//

import Testing

@testable import Patal

@Suite("신세벌 커스텀 처리기 테스트", .serialized)
struct HangulProcessorTests {
    @Test("유효한 문자만 받기")
    func setKey() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        var r1 = processor.verifyCombosable("i")
        #expect(r1 == true)

        r1 = processor.verifyCombosable("!")
        #expect(r1 == false)
    }

    @Test("ㄲ")
    func getComposedChar_ㄲ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposedCharacter()
        #expect(c1 == "\u{1100}")

        processor.rawChar = "k"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposedCharacter()
        #expect(c2 == "\u{1101}")
    }

    @Test("ㄱㄴ")
    func getComposedChar_ㄱㄴ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposedCharacter()
        #expect(c1 == "\u{1100}")

        processor.rawChar = "h"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.committed)
        let c2 = processor.getComposedCharacter()
        #expect(c2 == "\u{1102}")
    }

    @Test("ㄱㄱㄱ")
    func getComposedChar_ㄱㄱㄱ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposedCharacter()
        #expect(c1 == "\u{1100}")

        processor.rawChar = "k"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposedCharacter()
        #expect(c2 == "\u{1101}")

        processor.rawChar = "k"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposedCharacter()
        #expect(c3 == "\u{110F}")
    }

    @Test("ㄴㄷ")
    func getComposedChar_ㄴㄷ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "h"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposedCharacter()
        #expect(c1 == "\u{1102}")

        processor.rawChar = "u"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.committed)
        let c2 = processor.getComposedCharacter()
        #expect(c2 == "\u{1103}")
    }

    @Test("가")
    func getComposedChar_가() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        var r1 = processor.verifyCombosable("k")
        #expect(r1 == true)
        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposedCharacter()
        #expect(c1 == "ᄀ")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposedCharacter()
        #expect(c2 == "가")
    }

    @Test("나")
    func getComposedChar_나() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        var r1 = processor.verifyCombosable("h")
        #expect(r1 == true)
        processor.rawChar = "h"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposedCharacter()
        #expect(c1 == "ᄂ")

        r1 = processor.verifyCombosable("r")
        #expect(r1 == true)
        processor.rawChar = "r"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposedCharacter()
        #expect(c2 == "너")
    }

    @Test("까")
    func getComposedChar_까() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposedCharacter()
        #expect(c1 == "ᄀ")

        processor.rawChar = "k"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposedCharacter()
        #expect(c2 == "ᄁ")

        processor.rawChar = "f"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposedCharacter()
        #expect(c3 == "까")
    }

    @Test("강")
    func getComposedChar_강() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        var r1 = processor.verifyCombosable("k")
        #expect(r1 == true)
        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposedCharacter()
        #expect(c1 == "ᄀ")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposedCharacter()
        #expect(c2 == "가")

        r1 = processor.verifyCombosable("a")
        #expect(r1 == true)
        processor.rawChar = "a"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposedCharacter()
        #expect(c3 == "강")
    }

    //    @Test("강남")
    //    func getComposedChar_강남() {
    //        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")
    //
    //        var r1 = processor.bindRawCharacter(char: "k")
    //        #expect(r1 == true)
    //        if let (state1, test1) = processor.getComposedChar() {
    //            #expect(state1 == .composing)
    //            #expect(test1.hash == "ᄀ".hash)
    //            #expect(processor.preedit.count == 1)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "f")
    //        #expect(r1 == true)
    //        if let (state2, test2) = processor.getComposedChar() {
    //            #expect(state2 == .composing)
    //            #expect(test2.hash == "가".hash)
    //            #expect(processor.preedit.count == 2)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "a")
    //        #expect(r1 == true)
    //        if let (state3, test3) = processor.getComposedChar() {
    //            #expect(state3 == .none)
    //            #expect(test3 == "강")
    //            #expect(processor.preedit.isEmpty)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "h")
    //        #expect(r1 == true)
    //        if let (state4, test4) = processor.getComposedChar() {
    //            #expect(state4 == .composing)
    //            #expect(test4.hash == "ᄂ".hash)
    //            #expect(processor.preedit.count == 1)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "f")
    //        #expect(r1 == true)
    //        if let (state5, test5) = processor.getComposedChar() {
    //            #expect(state5 == .composing)
    //            #expect(test5.hash == "나".hash)
    //            #expect(processor.preedit.count == 2)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "z")
    //        #expect(r1 == true)
    //        if let (state6, test6) = processor.getComposedChar() {
    //            #expect(state6 == .none)
    //            #expect(test6 == "남")
    //            #expect(processor.preedit.isEmpty)
    //        }
    //    }
    //
    //    @Test("강_")
    //    func getComposedChar_강_남() {
    //        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")
    //
    //        var r1 = processor.bindRawCharacter(char: "k")
    //        #expect(r1 == true)
    //        if let (state1, test1) = processor.getComposedChar() {
    //            #expect(state1 == .composing)
    //            #expect(test1.hash == "ᄀ".hash)
    //            #expect(processor.preedit.count == 1)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "f")
    //        #expect(r1 == true)
    //        if let (state2, test2) = processor.getComposedChar() {
    //            #expect(state2 == .composing)
    //            #expect(test2.hash == "가".hash)
    //            #expect(processor.preedit.count == 2)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "a")
    //        #expect(r1 == true)
    //        if let (state3, test3) = processor.getComposedChar() {
    //            #expect(state3 == .none)
    //            #expect(test3 == "강")
    //            #expect(processor.preedit.isEmpty)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: " ")
    //        #expect(r1 == false)
    //        if let (state4, test4) = processor.getComposedChar() {
    //            #expect(state4 == .none)
    //            #expect(test4 == "강")
    //            #expect(processor.preedit.count == 0)
    //        }
    //    }
    //
    //    @Test("강^H")
    //    func getComposedChar_강백스페이스() {
    //        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")
    //
    //        var r1 = processor.bindRawCharacter(char: "k")
    //        #expect(r1 == true)
    //        if let (state1, test1) = processor.getComposedChar() {
    //            #expect(state1 == .composing)
    //            #expect(test1.hash == "ᄀ".hash)
    //            #expect(processor.preedit.count == 1)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "f")
    //        #expect(r1 == true)
    //        if let (state2, test2) = processor.getComposedChar() {
    //            #expect(state2 == .composing)
    //            #expect(test2.hash == "가".hash)
    //            #expect(processor.preedit.count == 2)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "a")
    //        #expect(r1 == true)
    //        if let (state3, test3) = processor.getComposedChar() {
    //            #expect(state3 == .none)
    //            #expect(test3 == "강")
    //            #expect(processor.preedit.isEmpty)
    //        }
    //
    //        r1 = processor.bindRawCharacter(char: "^H")
    //        #expect(r1 == false)
    //        if let (state4, test4) = processor.getComposedChar() {
    //            #expect(state4 == .committed)
    //            #expect(test4.hash == "".hash)
    //            #expect(processor.preedit.count == 0)
    //        }
    //    }
}
