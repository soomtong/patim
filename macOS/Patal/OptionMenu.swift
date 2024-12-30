//
//  OptionMenu.swift
//  Patal
//
//  Created by dp on 12/28/24.
//

import Cocoa
import Foundation

class OptionMenu {
    internal let logger = CustomLogger(category: "OptionMenu")

    var menu: NSMenu

    init(layout: HangulAutomata) {
        menu = NSMenu(title: "PatalLayoutMenu")
        logger.debug("자판의 모든 옵션: \(layout.availableTraits), 현재 선택된 옵션: \(layout.traits)")

        for trait in layout.availableTraits {
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

        menu.autoenablesItems = true
    }
}
