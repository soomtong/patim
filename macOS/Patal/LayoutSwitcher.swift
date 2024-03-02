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
        "com.apple.keylayout.US",
        "com.apple.keylayout.USExtended",
        "com.apple.keylayout.USInternational-PC",
        "com.apple.keylayout.Canadian",
        "com.apple.keylayout.British",
        "com.apple.keylayout.British-PC",
        "com.apple.keylayout.Australian",
        "com.apple.keylayout.ABC-India",
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
       
        // 클래스 생성시 전환할 자판을 선택
        selectedLayoutID =
            switchableLayoutIDList.first { isSwitchable(layoutID: $0) }
            ?? switchableLayoutIDList[0]
        
        logger.debug("선택된 영문 레이아웃: \(selectedLayoutID)")
    }

    func findCandidateLayout() -> String? {
        return switchableLayoutIDList.first { isSwitchable(layoutID: $0) }
    }

    func isSwitchable(layoutID: String) -> Bool {
        return self.availableLayouts.contains { inputSource in
            return inputSource.tisInputSource.id == layoutID
        }
    }

    func changeLayout() {
        // return
        logger.debug("ESC 키 입력됨 자판 전환: \(self.selectedLayoutID)")
    }
}
