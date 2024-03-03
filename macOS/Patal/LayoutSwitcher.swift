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

    // 현재 레이아웃을 저장
    let currentLayout: InputSource = InputSource.getCurrentLayout()
    // 입력기 목록 생성
    let candidateLayouts: [InputSource] = InputSource.sources
    var candidateLayout: InputSource?

    init() {
        logger.debug("레이아웃 선택기 생성")

        let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptionPrompt: true]
        isAppTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        logger.debug("보안 모드: \(isAppTrusted)")

        logger.debug("현재 팥알 레이아웃: \(currentLayout.tisInputSource.id)")
        // 클래스 생성시 전환할 자판을 선택
        candidateLayout = selectCandidateLayout()

        logger.debug("선택된 영문 레이아웃: \(String(describing: candidateLayout?.tisInputSource.id))")
    }
    
    func findCandidateLayouts() -> [InputSource] {
        return InputSource.sources
    }

    func selectCandidateLayout() -> InputSource {
        return candidateLayouts.first(where: { (layout: InputSource) -> Bool in
            return isSwitchable(layoutID: layout.tisInputSource.id)
        }) ?? currentLayout
    }

    func isSwitchable(layoutID: String) -> Bool {
        return switchableLayoutIDList.contains { $0 == layoutID }
    }

    func changeLayout() {
        logger.debug("ESC 키 입력됨 자판 전환: \(String(describing: candidateLayout?.tisInputSource.id))")
        // CJKV으로 변경 레이아웃은 추가 작업이 필요함 (잘 알려진 버그: https://github.com/pqrs-org/Karabiner-Elements/issues/1602)
        // 여기는 CJKV으로 변경이 아니기 때문에 필요하지 않음
        logger.debug("전환 전 상태: \(String(describing: currentLayout.tisInputSource.id)), \(String(describing: currentLayout.tisInputSource.sourceLanguages))")
        guard let inputSource = candidateLayout else { return }
        inputSource.select()
        logger.debug("전환 후 상태: \(inputSource.tisInputSource.id), \(inputSource.tisInputSource.sourceLanguages)")
        // let result = TISSelectInputSource(candicateLayout!.tisInputSource)
        // InputSource.postPreviousLayoutKey()
        // let current = InputSource.getCurrentLayout()
        // logger.debug("전환 결과: \(current.tisInputSource.id), \(current.tisInputSource.sourceLanguages)")
    }
}
