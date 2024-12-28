//
//  OptionMenu.swift
//  Patal
//
//  Created by dp on 12/28/24.
//

import Cocoa
import Foundation

class OptionMenu {
    let logger = CustomLogger(category: "OptionMenu")

    var menu: NSMenu

    init(layout: HangulAutomata) {
        self.menu = NSMenu()
        logger.debug("자판의 모든 옵션: \(layout.availableTraits)")

        for title in layout.availableTraits {
            let item = NSMenuItem()
            item.title = title.rawValue
            item.tag = title.hashValue
            item.action = #selector(InputController.changeLayoutOption(_:))
            item.isEnabled = true
            if layout.traits.contains(title) {
                item.state = NSControl.StateValue.on
            } else {
                item.state = NSControl.StateValue.off
            }
            self.menu.addItem(item)
        }

        self.menu.autoenablesItems = true
    }

    func getLayoutOptions(layout: Layout) -> [LayoutTrait] {
        return [LayoutTrait.화살표]
    }
}
