//
//  PatalTests.swift
//  PatalTests
//
//  Created by dp on 11/17/24.
//

import Testing

@testable import Patal

struct LayoutTests {
    let layout = Han3ShinPcsLayout()

    @Test()
    func pickChosung() {
        let 초성기역 = String(
            utf16CodeUnits: [초성.기역.rawValue],
            count: [초성.기역.rawValue].count
        )

        #expect(layout.pickChosung(by: "k") == 초성기역)
    }
}
