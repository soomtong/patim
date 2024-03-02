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

    var isAppTrusted: Bool
    
    let selfLayout: InputSource
    var selectedLayout: InputSource = InputSource.getCurrentLayout()
    
    init() {
        logger.debug("레이아웃 선택기 생성")
        
        let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptionPrompt: true]
        isAppTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        logger.debug("보안 모드: \(isAppTrusted)")
        
        // 현재 레이아웃을 저장
        selfLayout = self.selectedLayout
        logger.debug("현재 팥알 레이아웃: \(selfLayout.tisInputSource.id)")
        // 클래스 생성시 전환할 자판을 선택
        selectedLayout = self.findCandidateLayout()

        logger.debug("선택된 영문 레이아웃: \(selectedLayout.tisInputSource.id)")
    }

    func findCandidateLayout() -> InputSource {
        return InputSource.sources.first(where: { (layout: InputSource) -> Bool in
            return isSwitchable(layoutID: layout.tisInputSource.id)
        }) ?? selectedLayout
    }

    func isSwitchable(layoutID: String) -> Bool {
        return switchableLayoutIDList.contains { $0 == layoutID }
    }

    func changeLayout() {
        logger.debug("ESC 키 입력됨 자판 전환: \(selectedLayout.tisInputSource.id)")

        logger.debug("보안 모드: \(isAppTrusted)")
        
        if isAppTrusted || true {
            // CJKV 레이아웃은 추가 작업이 필요함 (잘 알려진 버그: https://github.com/pqrs-org/Karabiner-Elements/issues/1602)
            logger.debug("지금은 한글인가? \(selfLayout.isCJKV)")
            logger.debug("다음은 한글인가? \(selectedLayout.isCJKV)")
            logger.debug("한글인가 확인 후 한 번 더 전환")
            TISSelectInputSource(selectedLayout.tisInputSource)
            TISSelectInputSource(selfLayout.tisInputSource)
            InputSource.postPreviousLayoutKey()
        }
    }
}
