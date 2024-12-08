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

    @Test("글자 조합기")
    func getSyllableTest() {
        if let composition = HangulComposition(
            chosungPoint: "ㄱ",
            jungsungPoint: nil,
            jongsungPoint: nil
        ) {
            #expect(composition.getSyllable() == Character("ㄱ"))
        }
        if let composition = HangulComposition(
            chosungPoint: "ㄱ",
            jungsungPoint: "ㅏ",
            jongsungPoint: nil
        ) {
            #expect(composition.getSyllable() == Character("가"))
        }
        if let composition = HangulComposition(
            chosungPoint: "ㄱ",
            jungsungPoint: "ㅏ",
            jongsungPoint: "ㅇ"
        ) {
            #expect(composition.getSyllable() == Character("강"))
        }
        if let composition = HangulComposition("산") {
            #expect(composition.getSyllable() == Character("산"))
        }
        if let composition = HangulComposition("앎") {
            #expect(composition.getSyllable() == Character("앎"))
        }
    }

    @Suite("조합")
    struct CompositionTest {
        @Test
        func verifyCombination1() {
            if let composition = HangulComposition(
                chosungPoint: "ㄱ",
                jungsungPoint: nil,
                jongsungPoint: nil
            ) {
                #expect(composition.chosungPoint == Character("ㄱ"))
                #expect(composition.jungsungPoint == nil)
                #expect(composition.jongsungPoint == nil)
            }
        }
        @Test
        func verifyCombination1_1() {
            if let composition = HangulComposition(
                chosungPoint: "ㅎ",
                jungsungPoint: nil,
                jongsungPoint: nil
            ) {
                #expect(composition.chosungPoint == Character("ㅎ"))
                #expect(composition.jungsungPoint == nil)
                #expect(composition.jongsungPoint == nil)
            }
        }
        @Test
        func verifyCombination2() {
            if let composition = HangulComposition(
                chosungPoint: "ㄱ",
                jungsungPoint: "ㅏ",
                jongsungPoint: nil
            ) {
                #expect(composition.chosungPoint == Character("ㄱ"))
                #expect(composition.jungsungPoint == Character("ㅏ"))
                #expect(composition.jongsungPoint == nil)
            }
        }
        @Test
        func verifyCombination3() {
            if let composition = HangulComposition(
                chosungPoint: "ㄱ",
                jungsungPoint: "ㅏ",
                jongsungPoint: "ㅇ"
            ) {
                #expect(composition.chosungPoint == Character("ㄱ"))
                #expect(composition.jungsungPoint == Character("ㅏ"))
                #expect(composition.jongsungPoint == Character("ㅇ"))
            }
        }
    }

    @Suite("분해")
    struct DecompositionTest {
        @Test
        func verifyComposition1() {
            if let composition = HangulComposition("ㄱ") {
                #expect(composition.chosungPoint == Character("ㄱ"))
            }
        }
        @Test
        func verifyComposition1_1() {
            if let composition = HangulComposition("ㄴ") {
                #expect(composition.chosungPoint == Character("ㄴ"))
            }
        }
        @Test
        func verifyComposition1_2() {
            if let composition = HangulComposition("ㅎ") {
                #expect(composition.chosungPoint == Character("ㅎ"))
            }
        }
        @Test
        func verifyComposition2() {
            if let composition = HangulComposition("가") {
                #expect(composition.chosungPoint == Character("ㄱ"))
                #expect(composition.jungsungPoint == Character("ㅏ"))
            }
        }
        @Test
        func verifyComposition2_1() {
            if let composition = HangulComposition("나") {
                // 1176
                #expect(composition.chosungPoint == Character("ㄴ"))
                #expect(composition.jungsungPoint == Character("ㅏ"))
            }
        }
        @Test
        func verifyComposition3() {
            if let composition = HangulComposition("강") {
                #expect(composition.chosungPoint == Character("ㄱ"))
                #expect(composition.jungsungPoint == Character("ㅏ"))
                #expect(composition.jongsungPoint == Character("ㅇ"))
            }
        }
        @Test()
        func verifyComposition3_1() {
            if let composition = HangulComposition("곰") {
                #expect(composition.chosungPoint == Character("ㄱ"))
                #expect(composition.jungsungPoint == Character("ㅗ"))
                #expect(composition.jongsungPoint == Character("ㅁ"))
            }
        }
        @Test()
        func verifyComposition3_2() {
            if let composition = HangulComposition("널") {
                #expect(composition.chosungPoint == Character("ㄴ"))
                #expect(composition.jungsungPoint == Character("ㅓ"))
                #expect(composition.jongsungPoint == Character("ㄹ"))
            }
        }
        @Test()
        func verifyComposition3_3() {
            if let composition = HangulComposition("산") {
                #expect(composition.chosungPoint == Character("ㅅ"))
                #expect(composition.jungsungPoint == Character("ㅏ"))
                #expect(composition.jongsungPoint == Character("ㄴ"))
            }
        }
        @Test
        func verifyComposition3_4() {
            if let composition = HangulComposition("앎") {
                #expect(composition.chosungPoint == Character("ㅇ"))
                #expect(composition.jungsungPoint == Character("ㅏ"))
                #expect(composition.jongsungPoint == Character("ㄻ"))
            }
        }
        @Test
        func verifyComposition5() {
            if let composition = HangulComposition("ㅒ") {
                #expect(composition.chosungPoint == nil)
                #expect(composition.jungsungPoint == Character("ㅒ"))
            }
        }
        @Test
        func verifyComposition6() {
            if let composition = HangulComposition("ㄻ") {
                #expect(composition.chosungPoint == nil)
                #expect(composition.jungsungPoint == nil)
                #expect(composition.jongsungPoint == Character("ㄻ"))
            }
        }
    }
}
