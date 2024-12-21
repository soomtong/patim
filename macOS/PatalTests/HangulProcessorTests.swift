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
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1100}")

        processor.rawChar = "k"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1101}")
    }

    @Test("ㄱㄴ")
    func getComposedChar_ㄱㄴ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1100}")

        processor.rawChar = "h"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1102}")
    }

    @Test("ㄱㄱㄱ")
    func getComposedChar_ㄱㄱㄱ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1100}")

        processor.rawChar = "k"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1101}")

        processor.rawChar = "k"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "\u{110F}")
    }

    @Test("ㄴㄷ")
    func getComposedChar_ㄴㄷ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "h"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1102}")

        processor.rawChar = "u"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1103}")
    }

    @Test("ㄸ")
    func getComposedChar_ㄸ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "u"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1103}")

        processor.rawChar = "u"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1104}")
    }

    @Test("ㅋㅋ")
    func getComposedChar_ㅋㅋ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "."
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{110F}")

        processor.rawChar = "."
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{110F}")
    }

    @Test("ㅎㅎ")
    func getComposedChar_ㅎㅎ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "m"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1112}")

        processor.rawChar = "m"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1112}")
    }

    @Test("ㅏ", .disabled("미구현"))
    func getComposedChar_ㅏ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "F"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1161}")
    }

    @Test("ㄴ", .disabled("우선 순위를 정해야 함"))
    func getComposedChar_ㄴ() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "s"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{11AB}")
    }

    @Test("가")
    func getComposedChar_가() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        var r1 = processor.verifyCombosable("k")
        #expect(r1 == true)
        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ᄀ")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
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
        let c1 = processor.getComposed()
        #expect(c1 == "ᄂ")

        r1 = processor.verifyCombosable("r")
        #expect(r1 == true)
        processor.rawChar = "r"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "너")
    }

    @Test("까")
    func getComposedChar_까() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ᄀ")

        processor.rawChar = "k"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "ᄁ")

        processor.rawChar = "f"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "까")
    }

    @Test("의")
    func getComposedChar_의() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "j"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{110B}")

        processor.rawChar = "z"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "의")
    }

    @Test("매")
    func getComposedChar_매() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "i"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1106}")

        processor.rawChar = "e"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "매")
    }

    @Test("뫄")
    func getComposedChar_뫄() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "i"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1106}")

        processor.rawChar = "p"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "모")

        processor.rawChar = "f"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "뫄")
    }

    @Test("취")
    func getComposedChar_위() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "o"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{110E}")

        processor.rawChar = "o"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "추")

        processor.rawChar = "d"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "취")
    }

    @Test("강")
    func getComposedChar_강() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        var r1 = processor.verifyCombosable("k")
        #expect(r1 == true)
        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ᄀ")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "가")

        r1 = processor.verifyCombosable("a")
        #expect(r1 == true)
        processor.rawChar = "a"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "강")
    }

    @Test("공")
    func getComposedChar_공() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        processor.rawChar = "k"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ᄀ")

        processor.rawChar = "v"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "고")

        processor.rawChar = "a"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "공")
    }

    @Test("밖")
    func getComposedChar_밖() {
        let processor = HangulProcessor(layout: "InputmethodHan3ShinPCS")

        // 밖 ;fcc
        var r1 = processor.verifyCombosable(";")
        #expect(r1 == true)
        processor.rawChar = ";"
        let s1 = processor.composeBuffer()
        #expect(s1 == ComposeState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1107}")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.composeBuffer()
        #expect(s2 == ComposeState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "바")

        r1 = processor.verifyCombosable("c")
        #expect(r1 == true)
        processor.rawChar = "c"
        let s3 = processor.composeBuffer()
        #expect(s3 == ComposeState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "박")

        processor.rawChar = "c"
        let s4 = processor.composeBuffer()
        #expect(s4 == ComposeState.committed)
        let c4 = processor.getComposed()
        #expect(c4 == "밖")
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
