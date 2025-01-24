//
//  Logger.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/01.
//

import Foundation
import os

final class CustomLogger: Sendable {
    private let debugLogger: Logger

    init(category: String) {
        debugLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: category)
    }

    func debug(_ message: String = "") {
        // 프로덕션 배포하는 경우에는 false 로 전환하여 빌드
        let isDebug = true
        if isDebug {
            debugLogger.debug("\(message, privacy: .public)")
        }
    }

    func info(_ message: String = "") {
        debugLogger.info("\(message, privacy: .public)")
    }

    func error(_ message: String = "") {
        debugLogger.error("\(message, privacy: .public)")
    }
}
