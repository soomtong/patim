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
        #expect(layout.pickChosung(by: "k") == 초성기역)
    }
}
