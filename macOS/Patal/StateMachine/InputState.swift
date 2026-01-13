//
//  InputState.swift
//  Patal
//
//  상태 기계 상태 정의
//

import Foundation

/// 입력 상태 (기본 4상태)
/// 모아주기(느슨한 조합)는 can모아주기 플래그로 분기 처리
enum InputState: Equatable, CustomStringConvertible {
    /// 빈 상태 - 조합 없음
    case empty

    /// 초성만 있는 상태
    case initialConsonant

    /// 초성 + 중성
    case consonantVowel

    /// 초성 + 중성 + 종성 (완성)
    case consonantVowelFinal

    var description: String {
        switch self {
        case .empty:
            return "Empty"
        case .initialConsonant:
            return "InitialConsonant"
        case .consonantVowel:
            return "ConsonantVowel"
        case .consonantVowelFinal:
            return "ConsonantVowelFinal"
        }
    }

    /// 조합 중인지 여부
    var isComposing: Bool {
        self != .empty
    }
}
