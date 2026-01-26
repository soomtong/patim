//
//  HangulComposition.swift
//  PatalTests
//
//  Created by dp on 12/4/24.
//

import Testing

@testable import Patal

@Suite("한글 유니코드 조합")
struct HangulCompositionTest {
    @Test("오프셋 값")
    func verifyOffsets() {
        #expect(chosungOffset19 == 19)
        #expect(jungsungOffset21 == 21)
        #expect(jongsungOffset28 == 28)
    }

    // MARK: - 조합 테스트 데이터
    struct ConsonantTestCase: Sendable, CustomTestStringConvertible {
        let chosung: 초성
        let expected: Character
        var testDescription: String { String(expected) }
    }

    struct VowelTestCase: Sendable, CustomTestStringConvertible {
        let jungsung: 중성
        let expected: Character
        var testDescription: String { String(expected) }
    }

    struct SyllableTestCase: Sendable, CustomTestStringConvertible {
        let chosung: 초성
        let jungsung: 중성
        let expected: Character
        var testDescription: String { String(expected) }
    }

    struct FullSyllableTestCase: Sendable, CustomTestStringConvertible {
        let chosung: 초성
        let jungsung: 중성
        let jongsung: 종성
        let expected: Character
        var testDescription: String { String(expected) }
    }

    @Suite("조합")
    struct getSyllableTest {
        // MARK: - 닿소리 테스트
        static let consonantCases: [ConsonantTestCase] = [
            ConsonantTestCase(chosung: .기역, expected: "ㄱ"),
            ConsonantTestCase(chosung: .히읗, expected: "ㅎ"),
        ]

        @Test("닿소리", arguments: consonantCases)
        func consonantTest(testCase: ConsonantTestCase) throws {
            let composition = try #require(HangulComposer(
                chosungPoint: testCase.chosung,
                jungsungPoint: nil,
                jongsungPoint: nil
            ))
            #expect(composition.getSyllable() == testCase.expected)
        }

        // MARK: - 홀소리 테스트
        static let vowelCases: [VowelTestCase] = [
            VowelTestCase(jungsung: .아, expected: "ㅏ"),
        ]

        @Test("홀소리", arguments: vowelCases)
        func vowelTest(testCase: VowelTestCase) throws {
            let composition = try #require(HangulComposer(
                chosungPoint: nil,
                jungsungPoint: testCase.jungsung,
                jongsungPoint: nil
            ))
            #expect(composition.getSyllable() == testCase.expected)
        }

        // MARK: - 초성+중성 테스트
        static let syllableCases: [SyllableTestCase] = [
            SyllableTestCase(chosung: .기역, jungsung: .아, expected: "가"),
            SyllableTestCase(chosung: .니은, jungsung: .아, expected: "나"),
            SyllableTestCase(chosung: .니은, jungsung: .어, expected: "너"),
            SyllableTestCase(chosung: .쌍디귿, jungsung: .우, expected: "뚜"),
        ]

        @Test("초성+중성", arguments: syllableCases)
        func chosungAndJungsung(testCase: SyllableTestCase) throws {
            let composition = try #require(HangulComposer(
                chosungPoint: testCase.chosung,
                jungsungPoint: testCase.jungsung,
                jongsungPoint: nil
            ))
            #expect(composition.getSyllable() == testCase.expected)
        }

        // MARK: - 초성+중성+종성 테스트
        static let fullSyllableCases: [FullSyllableTestCase] = [
            FullSyllableTestCase(chosung: .기역, jungsung: .아, jongsung: .이응, expected: "강"),
            FullSyllableTestCase(chosung: .시옷, jungsung: .아, jongsung: .니은, expected: "산"),
            FullSyllableTestCase(chosung: .이응, jungsung: .와, jongsung: .이응, expected: "왕"),
            FullSyllableTestCase(chosung: .이응, jungsung: .아, jongsung: .리을미음, expected: "앎"),
        ]

        @Test("초성+중성+종성", arguments: fullSyllableCases)
        func chosungAndJungsungAndJongsung(testCase: FullSyllableTestCase) throws {
            let composition = try #require(HangulComposer(
                chosungPoint: testCase.chosung,
                jungsungPoint: testCase.jungsung,
                jongsungPoint: testCase.jongsung
            ))
            #expect(composition.getSyllable() == testCase.expected)
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
