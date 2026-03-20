//
//  SymbolExtension.swift
//  Patal
//
//  Created by dp on 3/20/26.
//

import Foundation

/// 기호 확장 상태
/// 불가능한 자소 조합(초+초, 중+중)을 트리거로 사용하여 기호 입력 모드를 전환한다
enum SymbolExtensionState: Equatable, Sendable {
    /// 비활성 (일반 한글 입력)
    case inactive
    /// 트리거 자소가 입력된 상태 (다음 키 대기)
    /// - 신세벌: ㅇ(j) 입력됨
    /// - 공세벌: /(ㅗ) 또는 9(ㅜ) 입력됨
    case triggered(triggerKey: String)
    /// 단 선택 완료 (기호 키 대기)
    case layerSelected(layerKey: String)
}

/// 트리거 판정에 필요한 버퍼 상태
enum TriggerBufferState: Sendable {
    /// 초성 단독 상태 (신세벌: ㅇ만 있는 상태)
    case initialConsonant
    /// 중성 단독 상태 (공세벌: ㅗ 또는 ㅜ만 있는 상태)
    case vowelOnly
}

/// 자판별 기호 확장 설정
struct SymbolExtensionConfig: Sendable {
    /// 트리거 키 (rawKey 기준)
    /// 이 키가 입력된 뒤 triggerState에 해당하는 상태가 되면 triggered
    let triggerKeys: Set<String>

    /// 트리거 판정에 필요한 버퍼 상태
    let triggerState: TriggerBufferState

    /// 단 선택 키 집합. triggered 상태에서 이 키가 오면 layerSelected로 전이
    let layerKeys: Set<String>

    /// 기호 맵: [단선택키][기호키] → 기호 문자열
    /// 기호키에 Shift가 적용되면 대문자로 구분 (예: "g" vs "G")
    let symbolMap: [String: [String: String]]
}
