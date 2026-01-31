//
//  OptionMenu.swift
//  Patal
//
//  Created by dp on 12/28/24.
//

import Cocoa
import Foundation

/// 입력기 메뉴 표시
class OptionMenu {
    internal let logger = CustomLogger(category: "OptionMenu")

    var menu: NSMenu

    init(layout: HangulAutomata) {
        menu = NSMenu(title: "PatalLayoutMenu")
        logger.debug("자판의 모든 옵션: \(layout.availableTraits), 현재 선택된 옵션: \(layout.traits)")

        let sortedTraits = Array(layout.availableTraits).sorted { $0.rawValue < $1.rawValue }
        for trait in sortedTraits {
            let item = NSMenuItem()
            item.title = trait.rawValue
            item.tag = trait.hashValue
            item.action = #selector(InputController.changeLayoutOption(_:))
            item.isEnabled = true
            if layout.traits.contains(trait) {
                item.state = NSControl.StateValue.on
            } else {
                item.state = NSControl.StateValue.off
            }

            menu.addItem(item)
        }

        // 구분선 추가
        let separator = NSMenuItem.separator()
        menu.addItem(separator)

        // 버전 정보 아이템 추가
        let versionItem = NSMenuItem()
        if let version = getMarketingVersion() {
            versionItem.title = "팥알입력기 v\(version)"
        } else {
            versionItem.title = "팥알입력기"
        }
        versionItem.isEnabled = false  // 클릭 불가, 표시만
        menu.addItem(versionItem)
    }
}
