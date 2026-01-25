//
//  TransitionResult.swift
//  Patal
//
//  Created by dp on 1/25/26.
//

import Foundation

/// 상태 전이 결과
enum TransitionResult: Equatable {
    /// 조합 중 (아직 완성되지 않음)
    case composing(SyllableBuffer)

    /// 커밋됨 (완성된 문자열과 다음 버퍼)
    case commit(String, nextBuffer: SyllableBuffer)

    /// 무효한 입력 (처리 불가)
    case invalid
}

extension TransitionResult {
    /// 기존 CommitState로 변환 (하위 호환성)
    var toCommitState: CommitState {
        switch self {
        case .composing:
            return .composing
        case .commit:
            return .committed
        case .invalid:
            return .none
        }
    }

    /// 결과 버퍼 (있는 경우)
    var buffer: SyllableBuffer? {
        switch self {
        case .composing(let buffer):
            return buffer
        case .commit(_, let nextBuffer):
            return nextBuffer
        case .invalid:
            return nil
        }
    }

    /// 커밋된 문자열 (있는 경우)
    var committedString: String? {
        switch self {
        case .commit(let string, _):
            return string
        default:
            return nil
        }
    }

    /// 조합 중인지
    var isComposing: Bool {
        if case .composing = self {
            return true
        }
        return false
    }

    /// 커밋되었는지
    var isCommitted: Bool {
        if case .commit = self {
            return true
        }
        return false
    }
}

// MARK: - 내부 전이 출력

/// 단일 전이의 내부 결과 (carryoverEvent 패턴용)
struct TransitionOutput: Equatable {
    /// 전이 액션
    let action: TransitionAction

    /// 다음 버퍼 상태
    let nextBuffer: SyllableBuffer

    /// 커밋된 문자열 (있는 경우)
    let committed: String?

    /// 이월 이벤트 (재처리 필요한 경우)
    let carryoverEvent: InputEvent?

    init(
        action: TransitionAction,
        nextBuffer: SyllableBuffer,
        committed: String? = nil,
        carryoverEvent: InputEvent? = nil
    ) {
        self.action = action
        self.nextBuffer = nextBuffer
        self.committed = committed
        self.carryoverEvent = carryoverEvent
    }
}

/// 전이 액션 종류
enum TransitionAction: Equatable {
    /// 버퍼만 업데이트 (커밋 없음)
    case updateBuffer

    /// 커밋 후 계속 (이월 이벤트 있을 수 있음)
    case commitAndContinue
}
