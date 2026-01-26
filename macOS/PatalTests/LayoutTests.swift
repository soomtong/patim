//
//  PatalTests.swift
//  PatalTests
//
//  Created by dp on 11/17/24.
//

import Testing

@testable import Patal

// MARK: - 레이아웃 테스트 데이터
struct ChosungTestCase: Sendable, CustomTestStringConvertible {
    let key: String
    let expected: 초성
    var testDescription: String { "\(key) → \(expected)" }
}

struct JungsungTestCase: Sendable, CustomTestStringConvertible {
    let key: String
    let expected: 중성
    var testDescription: String { "\(key) → \(expected)" }
}

struct JongsungTestCase: Sendable, CustomTestStringConvertible {
    let key: String
    let expected: 종성
    var testDescription: String { "\(key) → \(expected)" }
}

@Suite("레이아웃 테스트")
struct Han3ShinPcsLayoutTests {
    let layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)

    // MARK: - 초성 테스트
    static let chosungCases: [ChosungTestCase] = [
        ChosungTestCase(key: "k", expected: .기역),
        ChosungTestCase(key: "h", expected: .니은),
    ]

    static let doubleChosungCases: [ChosungTestCase] = [
        ChosungTestCase(key: "kk", expected: .쌍기역),
        ChosungTestCase(key: ";;", expected: .쌍비읍),
    ]

    @Test("초성 선택", arguments: chosungCases)
    func pickChosung(testCase: ChosungTestCase) {
        let result = layout.pickChosung(by: testCase.key)
        #expect(result == testCase.expected.rawValue)
    }

    @Test("겹초성 선택", arguments: doubleChosungCases)
    func pickDoubleChosung(testCase: ChosungTestCase) {
        let result = layout.pickChosung(by: testCase.key)
        #expect(result == testCase.expected.rawValue)
    }

    @Test("삼중 초성 선택", .disabled())
    func pickTripleChosung() {
        let result = layout.pickChosung(by: "kkk")
        #expect(result == 초성.키읔.rawValue)
    }

    // MARK: - 중성 테스트
    static let jungsungCases: [JungsungTestCase] = [
        JungsungTestCase(key: "f", expected: .아),
        JungsungTestCase(key: "e", expected: .애),
    ]

    static let doubleJungsungCases: [JungsungTestCase] = [
        JungsungTestCase(key: "pf", expected: .와),
        JungsungTestCase(key: "od", expected: .위),
        JungsungTestCase(key: "z", expected: .의),
    ]

    @Test("중성 선택", arguments: jungsungCases)
    func pickJungsung(testCase: JungsungTestCase) {
        let result = layout.pickJungsung(by: testCase.key)
        #expect(result == testCase.expected.rawValue)
    }

    @Test("겹중성 선택", arguments: doubleJungsungCases)
    func pickDoubleJungsung(testCase: JungsungTestCase) {
        let result = layout.pickJungsung(by: testCase.key)
        #expect(result == testCase.expected.rawValue)
    }

    // MARK: - 종성 테스트
    static let jongsungCases: [JongsungTestCase] = [
        JongsungTestCase(key: "a", expected: .이응),
        JongsungTestCase(key: "s", expected: .니은),
    ]

    static let doubleJongsungCases: [JongsungTestCase] = [
        JongsungTestCase(key: "cc", expected: .쌍기역),
        JongsungTestCase(key: "sd", expected: .니은히읗),
        JongsungTestCase(key: "we", expected: .리을비읍),
        JongsungTestCase(key: "x", expected: .쌍시옷),
    ]

    @Test("종성 선택", arguments: jongsungCases)
    func pickJongsung(testCase: JongsungTestCase) {
        let result = layout.pickJongsung(by: testCase.key)
        #expect(result == testCase.expected.rawValue)
    }

    @Test("겹종성 선택", arguments: doubleJongsungCases)
    func pickDoubleJongsung(testCase: JongsungTestCase) {
        let result = layout.pickJongsung(by: testCase.key)
        #expect(result == testCase.expected.rawValue)
    }

    // MARK: - 레이아웃 특성 테스트
    @Suite("레이아웃 특성 테스트")
    struct LayoutTraitTests {
        var layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)
        var processor: HangulProcessor!

        init() {
            layout.traits.insert(LayoutTrait.수정기호)
            processor = HangulProcessor(layout: layout)
        }

        @Test("초기 옵션")
        func loadTraits() {
            #expect(self.processor.hangulLayout.has수정기호 == true)
        }

        @Test("전체 특성 목록")
        func availableTraits() {
            let traits = layout.availableTraits
            #expect(traits.count > 0)
            #expect(traits.contains(LayoutTrait.수정기호))
        }
    }
}
