//
//  LayoutSwitcher.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation

class LayoutSwitcher {
    let logger = CustomLogger(category: "LayoutSwither")

    // 위에 있는 레이아웃이 우선권: 하나만 선택됨
    let switchableLayoutIDList: [String] = [
        "com.apple.keylayout.ABC",
        "com.apple.keylayout.USExtended",
        "com.apple.keylayout.US",
        "com.apple.keylayout.USInternational-PC",
        "com.apple.keylayout.Colemak",
        "com.apple.keylayout.Dvorak",
        "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman",
        "org.youknowone.inputmethod.Gureum.system",
    ]
    // 이게 핵심이군
    let availableLayouts = InputSource.sources
    var selectedLayoutID: String = ""

    init() {
        logger.debug("레이아웃 선택기 생성")
        //        selectedLayoutID = findCandidateLayout() ?? switchableLayoutIDList[0]
        selectedLayoutID =
            switchableLayoutIDList.first { isSwitchable(layoutID: $0) }
            ?? switchableLayoutIDList[0]
        logger.debug("선택된 영문 레이아웃: \(selectedLayoutID)")
    }

    func findCandidateLayout() -> String? {
        return switchableLayoutIDList.first { isSwitchable(layoutID: $0) }
        //        for layout in switchableLayoutIDList {
        //            if isSwitchable(layoutID: layout) {
        //                return layout
        //            }
        //        }
        //        return ""
    }

    func isSwitchable(layoutID: String) -> Bool {
        return self.availableLayouts.contains { inputSource in
            return inputSource.tisInputSource.id == layoutID
        }
    }

    func changeLayout(layout: String) {
        // return
        logger.debug("ESC 키 입력됨 자판 전환: \(layout)")
    }
}
