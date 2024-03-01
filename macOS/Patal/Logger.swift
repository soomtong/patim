//
//  Logger.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/01.
//

import os
import Foundation

func debug(_ message: String = "") {
    let isDebug = true
    if isDebug {
        // Logger().debug("\(message, privacy: .public)")
        os_log("\(message, privacy: .public)")
    }
}

// private var subsystem = Bundle.main.bundleIdentifier!
// let baseLogger = Logger(subsystem: subsystem, category: "baseLogger")
