//
//  PatalTests.swift
//  PatalTests
//
//  Created by dp on 11/17/24.
//

import Testing

@testable import Patal

@Suite("신세벌 커스텀 레이아웃 테스트", .serialized)
struct Han3ShinPcsLayoutTests {
    let layout = Han3ShinPcsLayout()
    let 초성기역 = String(
        utf16CodeUnits: [초성.기역.rawValue],
        count: [초성.기역.rawValue].count
    )

    @Test()
    func pickChosung() {
        let chosung1 = layout.pickChosung(by: "k")
        #expect(chosung1 == 초성.기역.rawValue)

        let chosung2 = layout.pickChosung(by: "h")
        #expect(chosung2 == 초성.니은.rawValue)
    }

    @Test()
    func pickDoubleChosung() {
        let doubleChosung1 = layout.pickChosung(by: "kk")
        #expect(doubleChosung1 == 초성.쌍기역.rawValue)

        let doubleChosung2 = layout.pickChosung(by: ";;")
        #expect(doubleChosung2 == 초성.쌍비읍.rawValue)
    }

    @Test(.disabled())
    func pickTripleChosung() {
        let doubleChosung1 = layout.pickChosung(by: "kkk")
        #expect(doubleChosung1 == 초성.키읔.rawValue)
    }

    @Test()
    func pickJungsung() {
        let jungsung1 = layout.pickJungsung(by: "f")
        #expect(jungsung1 == 중성.아.rawValue)

        let jungsung2 = layout.pickJungsung(by: "e")
        #expect(jungsung2 == 중성.애.rawValue)
    }

    @Test()
    func pickDoubleJungsung() {
        let doubleJungsung1 = layout.pickJungsung(by: "pf")
        #expect(doubleJungsung1 == 중성.와.rawValue)

        let doubleJungsung2 = layout.pickJungsung(by: "od")
        #expect(doubleJungsung2 == 중성.위.rawValue)

        let doubleJungsung3 = layout.pickJungsung(by: "z")
        #expect(doubleJungsung3 == 중성.의.rawValue)
    }

    @Test()
    func pickJongsung() {
        let jongsung1 = layout.pickJongsung(by: "a")
        #expect(jongsung1 == 종성.이응.rawValue)

        let jongsung2 = layout.pickJongsung(by: "s")
        #expect(jongsung2 == 종성.니은.rawValue)
    }

    @Test()
    func pickDoubleJongsung() {
        let doubleJongsung1 = layout.pickJongsung(by: "cc")
        #expect(doubleJongsung1 == 종성.쌍기역.rawValue)

        let doubleJongsung2 = layout.pickJongsung(by: "sd")
        #expect(doubleJongsung2 == 종성.니은히읗.rawValue)

        let doubleJongsung3 = layout.pickJongsung(by: "we")
        #expect(doubleJongsung3 == 종성.리을비읍.rawValue)

        let doubleJongsung4 = layout.pickJongsung(by: "x")
        #expect(doubleJongsung4 == 종성.쌍시옷.rawValue)
    }
}
