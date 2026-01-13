//
//  CompositionState.swift
//  Patal
//
//  조합 상태 데이터 (불변 구조체)
//

import Foundation

/// 조합 상태 데이터
/// 순수 데이터 컨테이너로 상태 전이 시 새 인스턴스 생성
struct CompositionState: Equatable {
    let chosung: 초성?
    let jungsung: 중성?
    let jongsung: 종성?

    /// 조합용 입력 버퍼 (겹자음/겹모음 처리용)
    let composingBuffer: [String]

    // MARK: - 초기화

    init(
        chosung: 초성? = nil,
        jungsung: 중성? = nil,
        jongsung: 종성? = nil,
        composingBuffer: [String] = []
    ) {
        self.chosung = chosung
        self.jungsung = jungsung
        self.jongsung = jongsung
        self.composingBuffer = composingBuffer
    }

    /// 빈 상태
    static let empty = CompositionState()

    // MARK: - 상태 계산

    /// 현재 InputState 계산 (기본 4상태)
    var inputState: InputState {
        switch (chosung, jungsung, jongsung) {
        case (nil, nil, nil):
            return .empty
        case (.some, nil, nil):
            return .initialConsonant
        case (.some, .some, nil):
            return .consonantVowel
        case (.some, .some, .some):
            return .consonantVowelFinal
        // 모아주기 상태들 - 기본 상태로 매핑
        case (nil, .some, nil):
            return .empty  // 중성만 (모아주기)
        case (nil, nil, .some):
            return .empty  // 종성만 (모아주기)
        case (.some, nil, .some):
            return .initialConsonant  // 초성+종성 (모아주기)
        case (nil, .some, .some):
            return .empty  // 중성+종성 (모아주기)
        }
    }

    /// 조합 중인지 여부
    var isComposing: Bool {
        chosung != nil || jungsung != nil || jongsung != nil
    }

    /// 조합 가능한 자모 개수
    var composableCount: Int {
        var count = 0
        if chosung != nil { count += 1 }
        if jungsung != nil { count += 1 }
        if jongsung != nil { count += 1 }
        return count
    }

    // MARK: - 상태 변경 헬퍼 (불변성 유지)

    func withChosung(_ value: 초성?, buffer: [String]? = nil) -> CompositionState {
        CompositionState(
            chosung: value,
            jungsung: jungsung,
            jongsung: jongsung,
            composingBuffer: buffer ?? composingBuffer
        )
    }

    func withJungsung(_ value: 중성?, buffer: [String]? = nil) -> CompositionState {
        CompositionState(
            chosung: chosung,
            jungsung: value,
            jongsung: jongsung,
            composingBuffer: buffer ?? composingBuffer
        )
    }

    func withJongsung(_ value: 종성?, buffer: [String]? = nil) -> CompositionState {
        CompositionState(
            chosung: chosung,
            jungsung: jungsung,
            jongsung: value,
            composingBuffer: buffer ?? composingBuffer
        )
    }

    func withBuffer(_ buffer: [String]) -> CompositionState {
        CompositionState(
            chosung: chosung,
            jungsung: jungsung,
            jongsung: jongsung,
            composingBuffer: buffer
        )
    }

    func appendingToBuffer(_ char: String) -> CompositionState {
        var newBuffer = composingBuffer
        newBuffer.append(char)
        return withBuffer(newBuffer)
    }

    /// 조합자로 변환 (기존 코드 호환용)
    func to조합자() -> 조합자 {
        조합자(chosung: chosung, jungsung: jungsung, jongsung: jongsung)
    }

    /// 조합자에서 생성 (기존 코드 호환용)
    static func from(_ preedit: 조합자, buffer: [String] = []) -> CompositionState {
        CompositionState(
            chosung: preedit.chosung,
            jungsung: preedit.jungsung,
            jongsung: preedit.jongsung,
            composingBuffer: buffer
        )
    }
}

// MARK: - CustomStringConvertible

extension CompositionState: CustomStringConvertible {
    var description: String {
        let cho = chosung.map { String(describing: $0) } ?? "nil"
        let jung = jungsung.map { String(describing: $0) } ?? "nil"
        let jong = jongsung.map { String(describing: $0) } ?? "nil"
        return "CompositionState(\(cho), \(jung), \(jong), buffer: \(composingBuffer))"
    }
}
