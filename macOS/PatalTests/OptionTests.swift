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
        let holders = [
            LayoutTrait.글자단위삭제.rawValue, LayoutTrait.수정기호.rawValue, LayoutTrait.빠른마침표.rawValue,
            LayoutTrait.옵션라틴.rawValue,
        ]

        init() {
            processor = HangulProcessor(layout: layout)
            // 초기 데이터를 가져오게 되었다고 가정한다.
            self.layout.traits = self.layout.availableTraits
            optionMenu = OptionMenu(layout: layout)
        }

        @Test("기본 세팅")
        func basicSetting() {
            #expect(optionMenu.menu.autoenablesItems == true)
            #expect(optionMenu.menu.numberOfItems == holders.count + 2)  // + 구분선, 버전정보

            let optionItems = optionMenu.menu.items.filter { holders.contains($0.title) }
            for menu in optionItems {
                #expect(menu.isEnabled == true)
                #expect(holders.contains(menu.title))
            }
        }

        @Test("신세벌PCS 모든 옵션")
        func loadDefaultTraits() {
            let optionItems = optionMenu.menu.items.filter { holders.contains($0.title) }
            for menu in optionItems {
                #expect(menu.state == NSControl.StateValue.on)
                #expect(holders.contains(menu.title))
            }
        }
    }

    @Suite("옵션라틴 trait")
    struct OptionLatinTraitTests {

        @Test("모든 자판에 옵션라틴 trait 포함")
        func allLayoutsHaveOptionLatinTrait() {
            let p3 = createLayoutInstance(name: LayoutName.HAN3_P3)
            let shinP2 = createLayoutInstance(name: LayoutName.HAN3_SHIN_P2)
            let shinPcs = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)

            #expect(p3.availableTraits.contains(LayoutTrait.옵션라틴))
            #expect(shinP2.availableTraits.contains(LayoutTrait.옵션라틴))
            #expect(shinPcs.availableTraits.contains(LayoutTrait.옵션라틴))
        }

        @Test("옵션라틴 기본값 비활성")
        func optionLatinDefaultOff() {
            let layout = createLayoutInstance(name: LayoutName.HAN3_P3)
            #expect(layout.can옵션라틴 == false)
        }

        @Test("옵션라틴 활성화 확인")
        func optionLatinCanBeEnabled() {
            var layout = createLayoutInstance(name: LayoutName.HAN3_P3)
            layout.traits.insert(LayoutTrait.옵션라틴)
            #expect(layout.can옵션라틴 == true)
        }

        @Test("Option+키 라틴 문자 매핑 (소문자)")
        func optionKeyLatinLowercase() {
            // Option 비트를 제거하고 SHIFT 없이 KeyCodeMapper 호출하면 소문자 라틴 문자
            let shiftOnly: UInt = 0
            // keyCode 0 = 'a' in physicalKeyMap
            let result = KeyCodeMapper.mapKeyCodeToHangulChar(keyCode: 0, modifiers: shiftOnly)
            #expect(result == "a")
            // keyCode 12 = 'q'
            let resultQ = KeyCodeMapper.mapKeyCodeToHangulChar(keyCode: 12, modifiers: shiftOnly)
            #expect(resultQ == "q")
        }

        @Test("Option+Shift+키 라틴 문자 매핑 (대문자)")
        func optionShiftKeyLatinUppercase() {
            // Option+Shift에서 ALT 비트를 제거하면 SHIFT만 남음
            let shiftOnly = ModifierCode.SHIFT.rawValue
            // keyCode 0 = 'A' in shiftKeyMap
            let result = KeyCodeMapper.mapKeyCodeToHangulChar(keyCode: 0, modifiers: shiftOnly)
            #expect(result == "A")
            // keyCode 12 = 'Q'
            let resultQ = KeyCodeMapper.mapKeyCodeToHangulChar(keyCode: 12, modifiers: shiftOnly)
            #expect(resultQ == "Q")
        }
    }

    @Suite("수정 옵션 1")
    struct Active수정기호OnTests {
        var layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)
        var optionMenu: OptionMenu!

        init() {
            // 이전 옵션 상태가 비활성화 되었다고 가정한다.
            layout.traits.removeAll()
            optionMenu = OptionMenu(layout: layout)
        }

        @Test("신세벌PCS 모든 옵션 비활성화")
        func loadOverrideTraits() {
            let optionItems = optionMenu.menu.items.filter { !$0.isSeparatorItem && $0.isEnabled }
            for menu in optionItems {
                #expect(menu.state == NSControl.StateValue.off)
            }
        }
    }
}
