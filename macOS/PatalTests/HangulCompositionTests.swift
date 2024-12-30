//
//  HangulComposition.swift
//  PatalTests
//
//  Created by dp on 12/4/24.
//

import Testing

@testable import Patal

@Suite("한글 유니코드 조합", .serialized)
struct HangulCompositionTest {
    @Test("오프셋 값")
    func verifyOffsets() {
        #expect(chosungOffset19 == 19)
        #expect(jungsungOffset21 == 21)
        #expect(jongsungOffset28 == 28)
    }

    @Suite("조합")
    struct getSyllableTest {
        @Test("닿소리")
        func consonantTest() {
            if let composition = HangulComposer(
                chosungPoint: 초성.기역,
                jungsungPoint: nil,
                jongsungPoint: nil
            ) {
                let _: Character = "\u{1100}"
                let 호환_ㄱ: Character = "ㄱ"
                #expect(composition.getSyllable() == 호환_ㄱ)
                #expect(composition.chosungCode == 초성.기역)
                #expect(composition.jungsungCode == nil)
                #expect(composition.jongsungCode == nil)
            }

            if let composition = HangulComposer(
                chosungPoint: 초성.히읗,
                jungsungPoint: nil,
                jongsungPoint: nil
            ) {
                let _: Character = "\u{1112}"
                let 호환_ㅎ: Character = "ㅎ"
                #expect(composition.getSyllable() == 호환_ㅎ)
                #expect(composition.chosungCode == 초성.히읗)
                #expect(composition.jungsungCode == nil)
                #expect(composition.jongsungCode == nil)
            }
        }

        @Test("홀소리")
        func vowelTest() {
            if let composition = HangulComposer(
                chosungPoint: nil,
                jungsungPoint: 중성.아,
                jongsungPoint: nil
            ) {
                let _: Character = "\u{1161}"
                let 호환_ㅏ: Character = "ㅏ"
                #expect(composition.getSyllable() == 호환_ㅏ)
                #expect(composition.chosungCode == nil)
                #expect(composition.jungsungCode == 중성.아)
                #expect(composition.jongsungCode == nil)
            }
        }

        @Test("초성+중성")
        func chosungAndJungsung() {
            if let composition = HangulComposer(
                chosungPoint: 초성.init(rawValue: 0x1100),
                jungsungPoint: 중성.init(rawValue: 0x1161),
                jongsungPoint: nil
            ) {
                #expect(composition.getSyllable() == Character("가"))
                #expect(composition.chosungCode == 초성.기역)
                #expect(composition.jungsungCode == 중성.아)
                #expect(composition.jongsungCode == nil)
            }
            if let composition = HangulComposer(
                chosungPoint: 초성.기역,
                jungsungPoint: 중성.아,
                jongsungPoint: nil
            ) {
                #expect(composition.getSyllable() == Character("가"))
            }
            if let composition = HangulComposer(
                chosungPoint: 초성.니은,
                jungsungPoint: 중성.아,
                jongsungPoint: nil
            ) {
                #expect(composition.getSyllable() == Character("나"))
            }
            if let composition = HangulComposer(
                chosungPoint: 초성.니은,
                jungsungPoint: 중성.어,
                jongsungPoint: nil
            ) {
                #expect(composition.getSyllable() == Character("너"))
            }
            if let composition = HangulComposer(
                chosungPoint: 초성.쌍디귿,
                jungsungPoint: 중성.우,
                jongsungPoint: nil
            ) {
                #expect(composition.getSyllable() == Character("뚜"))
            }
        }

        @Test("초성+중성+종성")
        func chosungAndJungsungAndJongsung() {
            if let composition = HangulComposer(
                chosungPoint: 초성.기역,
                jungsungPoint: 중성.아,
                jongsungPoint: 종성.이응
            ) {
                #expect(composition.getSyllable() == Character("강"))
                #expect(composition.chosungCode == 초성.기역)
                #expect(composition.jungsungCode == 중성.아)
                #expect(composition.jongsungCode == 종성.이응)
            }
            if let composition = HangulComposer(
                chosungPoint: 초성.시옷,
                jungsungPoint: 중성.아,
                jongsungPoint: 종성.니은
            ) {
                #expect(composition.getSyllable() == Character("산"))
                #expect(composition.chosungCode == 초성.시옷)
                #expect(composition.jungsungCode == 중성.아)
                #expect(composition.jongsungCode == 종성.니은)
            }
            if let composition = HangulComposer(
                chosungPoint: 초성.이응,
                jungsungPoint: 중성.와,
                jongsungPoint: 종성.이응
            ) {
                #expect(composition.getSyllable() == Character("왕"))
            }

            if let composition = HangulComposer(
                chosungPoint: 초성.이응,
                jungsungPoint: 중성.아,
                jongsungPoint: 종성.리을미음
            ) {
                #expect(composition.getSyllable() == Character("앎"))
                #expect(composition.chosungCode == 초성.이응)
                #expect(composition.jungsungCode == 중성.아)
                #expect(composition.jongsungCode == 종성.리을미음)
            }
        }
    }

    //    @Suite("분해")
    //    struct DecompositionTest {
    //        @Test
    //        func verifyComposition1() {
    //            if let composition = HangulComposition("ㄱ") {
    //                #expect(composition.chosungPoint == Character("ㄱ"))
    //            }
    //        }
    //        @Test
    //        func verifyComposition1_1() {
    //            if let composition = HangulComposition("ㄴ") {
    //                #expect(composition.chosungPoint == Character("ㄴ"))
    //            }
    //        }
    //        @Test
    //        func verifyComposition1_2() {
    //            if let composition = HangulComposition("ㅎ") {
    //                #expect(composition.chosungPoint == Character("ㅎ"))
    //            }
    //        }
    //        @Test
    //        func verifyComposition2() {
    //            if let composition = HangulComposition("가") {
    //                #expect(composition.chosungPoint == Character("ㄱ"))
    //                #expect(composition.jungsungPoint == Character("ㅏ"))
    //            }
    //        }
    //        @Test
    //        func verifyComposition2_1() {
    //            if let composition = HangulComposition("나") {
    //                // 1176
    //                #expect(composition.chosungPoint == Character("ㄴ"))
    //                #expect(composition.jungsungPoint == Character("ㅏ"))
    //            }
    //        }
    //        @Test
    //        func verifyComposition3() {
    //            if let composition = HangulComposition("강") {
    //                #expect(composition.chosungPoint == Character("ㄱ"))
    //                #expect(composition.jungsungPoint == Character("ㅏ"))
    //                #expect(composition.jongsungPoint == Character("ㅇ"))
    //            }
    //        }
    //        @Test()
    //        func verifyComposition3_1() {
    //            if let composition = HangulComposition("곰") {
    //                #expect(composition.chosungPoint == Character("ㄱ"))
    //                #expect(composition.jungsungPoint == Character("ㅗ"))
    //                #expect(composition.jongsungPoint == Character("ㅁ"))
    //            }
    //        }
    //        @Test()
    //        func verifyComposition3_2() {
    //            if let composition = HangulComposition("널") {
    //                #expect(composition.chosungPoint == Character("ㄴ"))
    //                #expect(composition.jungsungPoint == Character("ㅓ"))
    //                #expect(composition.jongsungPoint == Character("ㄹ"))
    //            }
    //        }
    //        @Test()
    //        func verifyComposition3_3() {
    //            if let composition = HangulComposition("산") {
    //                #expect(composition.chosungPoint == Character("ㅅ"))
    //                #expect(composition.jungsungPoint == Character("ㅏ"))
    //                #expect(composition.jongsungPoint == Character("ㄴ"))
    //            }
    //        }
    //        @Test
    //        func verifyComposition3_4() {
    //            if let composition = HangulComposition("앎") {
    //                #expect(composition.chosungPoint == Character("ㅇ"))
    //                #expect(composition.jungsungPoint == Character("ㅏ"))
    //                #expect(composition.jongsungPoint == Character("ㄻ"))
    //            }
    //        }
    //        @Test
    //        func verifyComposition5() {
    //            if let composition = HangulComposition("ㅒ") {
    //                #expect(composition.chosungPoint == nil)
    //                #expect(composition.jungsungPoint == Character("ㅒ"))
    //            }
    //        }
    //        @Test
    //        func verifyComposition6() {
    //            if let composition = HangulComposition("ㄻ") {
    //                #expect(composition.chosungPoint == nil)
    //                #expect(composition.jungsungPoint == nil)
    //                #expect(composition.jongsungPoint == Character("ㄻ"))
    //            }
    //        }
    //    }
}
