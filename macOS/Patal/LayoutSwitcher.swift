//
//  LayoutSwitcher.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Carbon
import Foundation

class LayoutSwitcher {
    let logger = CustomLogger(category: "LayoutSwither")

    // 위에 있는 레이아웃이 우선권: 하나만 선택됨
    let switchableLayoutIDList = [
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

    var selectedLayout: InputSource = InputSource.getCurrentLayout()

    init() {
        logger.debug("레이아웃 선택기 생성")

        // 클래스 생성시 전환할 자판을 선택
        self.selectedLayout = self.findCandidateLayout()

        logger.debug("선택된 영문 레이아웃: \(selectedLayout.tisInputSource.id)")
    }

    func findCandidateLayout() -> InputSource {
        return InputSource.sources.first(where: { (layout: InputSource) -> Bool in
            return isSwitchable(layoutID: layout.tisInputSource.id)
        }) ?? selectedLayout
    }
    //    func findCandidateLayout() -> InputSource {
    //        return InputSource.sources.first { isSwitchable(layoutID: $0.tisInputSource.id) } ?? selectedLayout
    //    }

    func isSwitchable(layoutID: String) -> Bool {
        return switchableLayoutIDList.contains { $0 == layoutID }
    }

    func changeLayout() {
        // return
        logger.debug("ESC 키 입력됨 자판 전환: \(selectedLayout.tisInputSource.id)")
        TISSelectInputSource(selectedLayout.tisInputSource)
    }
}
