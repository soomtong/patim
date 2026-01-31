//
//  SyllableBuffer.swift
//  Patal
//
//  Created by dp on 1/25/26.
//

import Foundation

/// 조합 중인 음절 데이터
struct SyllableBuffer: Equatable {
    /// 초성
    var chosung: 초성?

    /// 중성
    var jungsung: 중성?

    /// 종성
    var jongsung: 종성?

    /// 겹자음/겹모음 판정용 키 버퍼 (기존 composing 역할)
    var composingKeys: [String]

    /// 백스페이스 복원용 키 히스토리 (기존 keyHistory 역할)
    var keyHistory: [String]

    /// composingKeys.joined() 캐시 (성능 최적화)
    private var _composedKey: String = ""

    /// 빈 버퍼
    static let empty = SyllableBuffer(
        chosung: nil,
        jungsung: nil,
        jongsung: nil,
        composingKeys: [],
        keyHistory: []
    )

    init(
        chosung: 초성? = nil,
        jungsung: 중성? = nil,
        jongsung: 종성? = nil,
        composingKeys: [String] = [],
        keyHistory: [String] = []
    ) {
        self.chosung = chosung
        self.jungsung = jungsung
        self.jongsung = jongsung
        self.composingKeys = composingKeys
        self.keyHistory = keyHistory
        self._composedKey = composingKeys.joined()
    }

    /// composingKeys의 joined() 캐시 (O(1) 접근)
    var composedKey: String {
        return _composedKey
    }

    /// 현재 상태 (computed)
    var state: CompositionState {
        return CompositionState.from(
            hasChosung: chosung != nil,
            hasJungsung: jungsung != nil,
            hasJongsung: jongsung != nil
        )
    }

    /// 비어있는지
    var isEmpty: Bool {
        return state == .empty
    }

    /// 조합 가능한 낱자 수
    var composableCount: Int {
        var count = 0
        if chosung != nil { count += 1 }
        if jungsung != nil { count += 1 }
        if jongsung != nil { count += 1 }
        return count
    }
}

// MARK: - 조합자 변환

extension SyllableBuffer {
    /// 기존 조합자로 변환
    func to조합자() -> 조합자 {
        return 조합자(
            chosung: chosung,
            jungsung: jungsung,
            jongsung: jongsung
        )
    }

    /// 기존 조합자에서 생성
    init(from 조합자: 조합자) {
        self.chosung = 조합자.chosung
        self.jungsung = 조합자.jungsung
        self.jongsung = 조합자.jongsung
        self.composingKeys = []
        self.keyHistory = []
    }

    /// 기존 조합자와 버퍼 정보로 생성
    init(from 조합자: 조합자, composingKeys: [String], keyHistory: [String]) {
        self.chosung = 조합자.chosung
        self.jungsung = 조합자.jungsung
        self.jongsung = 조합자.jongsung
        self.composingKeys = composingKeys
        self.keyHistory = keyHistory
    }
}

// MARK: - 버퍼 조작

extension SyllableBuffer {
    /// composingKeys 초기화 후 새 키 설정
    mutating func resetComposingKeys(_ key: String) {
        composingKeys.removeAll()
        composingKeys.append(key)
        _composedKey = key
    }

    /// composingKeys에 키 추가
    mutating func appendComposingKey(_ key: String) {
        composingKeys.append(key)
        _composedKey.append(key)
    }

    /// keyHistory에 키 추가
    mutating func appendKeyHistory(_ key: String) {
        keyHistory.append(key)
    }

    /// keyHistory에서 마지막 키 제거
    @discardableResult
    mutating func removeLastKeyHistory() -> String? {
        guard !keyHistory.isEmpty else { return nil }
        return keyHistory.removeLast()
    }

    /// 모든 버퍼 초기화
    mutating func clear() {
        chosung = nil
        jungsung = nil
        jongsung = nil
        composingKeys.removeAll()
        keyHistory.removeAll()
        _composedKey = ""
    }

    /// preedit만 초기화 (keyHistory 유지)
    mutating func clearPreedit() {
        chosung = nil
        jungsung = nil
        jongsung = nil
        composingKeys.removeAll()
        _composedKey = ""
    }
}

// MARK: - 디버깅

extension SyllableBuffer: CustomStringConvertible {
    var description: String {
        let cho = chosung.map { String(describing: $0) } ?? "nil"
        let jung = jungsung.map { String(describing: $0) } ?? "nil"
        let jong = jongsung.map { String(describing: $0) } ?? "nil"
        return "SyllableBuffer(\(cho), \(jung), \(jong)) keys:\(composingKeys) history:\(keyHistory)"
    }
}
