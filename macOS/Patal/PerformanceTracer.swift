//
//  PerformanceTracer.swift
//  Patal
//
//  Created for debugging input method switch delay
//

import Foundation
import os

@available(macOS 12.0, *)
final class PerformanceTracer: Sendable {
    static let shared = PerformanceTracer()

    private let logger: Logger
    private let signposter: OSSignposter

    private init() {
        logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.soomtong.inputmethod",
            category: "Performance"
        )
        signposter = OSSignposter(logger: logger)
    }

    // MARK: - os_signpost 기반 측정 (Instruments 연동)

    func beginInterval(_ name: StaticString) -> OSSignpostIntervalState {
        let id = signposter.makeSignpostID()
        return signposter.beginInterval(name, id: id)
    }

    func endInterval(_ name: StaticString, _ state: OSSignpostIntervalState) {
        signposter.endInterval(name, state)
    }

    // MARK: - 간편 측정 메서드

    @discardableResult
    func measure<T>(_ label: String, block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            logger.info("[\(label, privacy: .public)] \(elapsed, format: .fixed(precision: 3))ms")
        }
        return try block()
    }

    // MARK: - 비동기 측정

    func measureAsync(_ label: String) -> () -> Void {
        let start = CFAbsoluteTimeGetCurrent()
        return { [self] in
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            logger.info("[\(label, privacy: .public)] \(elapsed, format: .fixed(precision: 3))ms")
        }
    }

    // MARK: - 단순 로그

    func log(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    // MARK: - 비동기 로깅 (hot path 최적화)

    /// 비동기로 성능 메트릭을 기록 (hot path에서 블로킹 제거)
    func recordAsync(_ label: String, latency: Double) {
        Task.detached(priority: .background) { [logger] in
            logger.info("[\(label, privacy: .public)] \(latency, format: .fixed(precision: 3))ms")
        }
    }

    /// 비동기로 메시지를 로깅
    func logAsync(_ message: String) {
        Task.detached(priority: .background) { [logger] in
            logger.info("\(message, privacy: .public)")
        }
    }
}

// MARK: - 하위 버전 호환용 Fallback

enum PerformanceTracerCompat {
    @available(macOS 12.0, *)
    static var tracer: PerformanceTracer {
        return PerformanceTracer.shared
    }

    static func measure<T>(_ label: String, block: () throws -> T) rethrows -> T {
        if #available(macOS 12.0, *) {
            return try tracer.measure(label, block: block)
        } else {
            return try block()
        }
    }

    static func measureAsync(_ label: String) -> () -> Void {
        if #available(macOS 12.0, *) {
            return tracer.measureAsync(label)
        } else {
            return {}
        }
    }
}
