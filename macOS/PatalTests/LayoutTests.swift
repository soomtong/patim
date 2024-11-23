//
//  PatalTests.swift
//  PatalTests
//
//  Created by dp on 11/17/24.
//

import Testing

@testable import Patal

@Suite("신세벌 커스텀 레이아웃 테스트")
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
    func pickJungsung() {
        let jungsung1 = layout.pickJungsung(by: "f")
        #expect(jungsung1 == 중성.아.rawValue)

        let jungsung2 = layout.pickJungsung(by: "e")
        #expect(jungsung2 == 중성.애.rawValue)
    }

    @Test()
    func pickJongsung() {
        let jongsung1 = layout.pickJongsung(by: "a")
        #expect(jongsung1 == 종성.이응.rawValue)

        let jongsung2 = layout.pickJongsung(by: "s")
        #expect(jongsung2 == 종성.니은.rawValue)
    }
}
