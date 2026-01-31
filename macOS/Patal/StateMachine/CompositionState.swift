//
//  CompositionState.swift
//  Patal
//
//  Created by dp on 1/25/26.
//

import Foundation

/// 한글 조합의 8가지 명시적 상태
/// 초성/중성/종성의 존재 여부 조합으로 결정됨
enum CompositionState: Equatable, Hashable, Sendable {
    /// 빈 상태: (nil, nil, nil)
    case empty

    /// 초성만 있음: (초, nil, nil)
    case initialConsonant

    /// 중성만 있음: (nil, 중, nil) - 모아주기 모드
    case vowelOnly

    /// 종성만 있음: (nil, nil, 종) - 모아주기 모드
    case finalOnly

    /// 초성+중성: (초, 중, nil)
    case consonantVowel

    /// 중성+종성: (nil, 중, 종) - 모아주기 모드
    case vowelFinal

    /// 초성+종성: (초, nil, 종) - 모아주기 모드
    case consonantFinal

    /// 완전한 음절: (초, 중, 종)
    case consonantVowelFinal
}

extension CompositionState {
    /// 초성/중성/종성 존재 여부로 상태 결정
    static func from(
        hasChosung: Bool,
        hasJungsung: Bool,
        hasJongsung: Bool
    ) -> CompositionState {
        switch (hasChosung, hasJungsung, hasJongsung) {
        case (false, false, false): return .empty
        case (true, false, false): return .initialConsonant
        case (false, true, false): return .vowelOnly
        case (false, false, true): return .finalOnly
        case (true, true, false): return .consonantVowel
        case (false, true, true): return .vowelFinal
        case (true, false, true): return .consonantFinal
        case (true, true, true): return .consonantVowelFinal
        }
    }

    /// 조합 가능한 상태인지 (완성 가능 여부와 별개)
    var isComposing: Bool {
        return self != .empty
    }

    /// 현대 한글로 완성 가능한 상태인지
    /// 초성+중성 또는 초성+중성+종성 조합만 현대 한글로 완성됨
    var canComposeModernHangul: Bool {
        switch self {
        case .consonantVowel, .consonantVowelFinal:
            return true
        default:
            return false
        }
    }

    /// 모아주기 전용 상태인지
    var requiresMoachigi: Bool {
        switch self {
        case .vowelOnly, .finalOnly, .vowelFinal, .consonantFinal:
            return true
        default:
            return false
        }
    }
}
