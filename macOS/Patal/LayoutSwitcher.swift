//
//  LayoutSwitcher.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation

class LayoutSwitcher {
    let logger = CustomLogger(category: "LayoutSwither")

    init() {}

    func change(layout: String) {
        // return
        logger.debug("ESC 키 입력됨 자판 전환: \(layout)")
    }
}
