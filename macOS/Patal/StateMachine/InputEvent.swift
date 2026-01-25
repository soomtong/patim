//
//  InputEvent.swift
//  Patal
//
//  Created by dp on 1/25/26.
//

import Foundation

/// 한글 조합 입력 이벤트
/// 자소 타입별로 분리하여 패턴 매칭 활용
enum InputEvent: Equatable {
    /// 초성 입력
    case chosung(초성)

    /// 중성 입력
    case jungsung(중성)

    /// 종성 입력
    case jongsung(종성)

    /// 백스페이스
    case backspace

    /// 조합 종료 (포커스 변경, 커서 이동, 엔터 등)
    case flush
}

extension InputEvent {
    /// 입력 이벤트 종류
    var kind: InputEventKind {
        switch self {
        case .chosung: return .chosung
        case .jungsung: return .jungsung
        case .jongsung: return .jongsung
        case .backspace: return .backspace
        case .flush: return .flush
        }
    }

    /// 자소 이벤트인지
    var isJamo: Bool {
        switch self {
        case .chosung, .jungsung, .jongsung:
            return true
        default:
            return false
        }
    }
}

/// 입력 이벤트 종류 (패턴 매칭용)
enum InputEventKind: Equatable {
    case chosung
    case jungsung
    case jongsung
    case backspace
    case flush
}
