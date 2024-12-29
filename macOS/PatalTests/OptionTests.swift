//
//  OptionTests.swift
//  PatalTests
//
//  Created by dp on 12/29/24.
//

import AppKit
import Testing

@testable import Patal

@Suite("옵션 메뉴 테스트", .serialized)
struct OptionTests {

    @Suite("기본 옵션")
    struct DefaultTests {
        var layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)
        var processor: HangulProcessor!
        var optionMenu: OptionMenu!

        init() {
            processor = HangulProcessor(layout: layout)
            // 초기 데이터를 가져오게 되었다고 가정한다.
            self.layout.traits = self.layout.availableTraits
            optionMenu = OptionMenu(layout: layout)
        }

        @Test("기본 세팅")
        func basicSetting() {
            #expect(optionMenu.menu.autoenablesItems == true)
            for menu in optionMenu.menu.items {
                #expect(menu.isEnabled == true)
                #expect(menu.title == LayoutTrait.화살표.rawValue)
            }
        }

        @Test("신세벌 커스텀 화살표 옵션")
        func loadDefaultTraits() {
            for menu in optionMenu.menu.items {
                #expect(menu.state == NSControl.StateValue.on)
            }
        }
    }

    @Suite("수정 옵션 1")
    struct Active화살표OnTests {
        var layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)
        var optionMenu: OptionMenu!

        init() {
            // 이전 옵션 상태가 비활성화 되었다고 가정한다.
            layout.traits.removeAll()
            optionMenu = OptionMenu(layout: layout)
        }

        @Test("신세벌 커스텀 화살표 비활성화")
        func loadOverrideTraits() {
            for menu in optionMenu.menu.items {
                #expect(menu.isEnabled == true)
                #expect(menu.title == LayoutTrait.화살표.rawValue)
                #expect(menu.state == NSControl.StateValue.off)
            }
        }
    }
}
