//
//  Logger.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/01.
//

import Foundation
import os

class CustomLogger {
    let debugLogger: Logger

    init(category: String) {
        debugLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: category)
    }

    func debug(_ message: String = "") {
        let isDebug = true
        if isDebug {
            debugLogger.debug("\(message, privacy: .public)")
        }
    }

    func error(_ message: String = "") {
        debugLogger.error("\(message, privacy: .public)")
    }
}
