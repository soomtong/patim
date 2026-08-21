//
//  Util.swift
//  Patal
//
//  Created by dp on 12/2/24.
//

import Carbon
import Foundation

func loadActiveOptions(traitKey: String) -> Set<LayoutTrait>? {
    if let dump = retrieveUserTraits(traitKey: traitKey) {
        let loadedTraits = dump.split(separator: ",")
        if loadedTraits.count < 1 || loadedTraits.isEmpty {
            return []
        }
        var traits: Set<LayoutTrait> = []
        loadedTraits.forEach { label in
            let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
            if let trait = LayoutTrait(rawValue: trimmed) {
                traits.insert(trait)
            }
        }
        return traits
    } else {
        return nil
    }
}

func keepUserTraits(traitKey: String, traitValue: String) {
    UserDefaults.standard.set(traitValue, forKey: traitKey)
    // synchronize() 제거 - deprecated API, 현대 macOS에서 자동 저장됨
}

func retrieveUserTraits(traitKey: String) -> String? {
    return UserDefaults.standard.string(forKey: traitKey)
}

func buildTraitKey(name: LayoutName) -> String {
    return "LayoutOption." + name.rawValue
}

func getCurrentInputMethodID() -> String? {
    // Get the current input source
    guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
        return nil
    }

    // Extract the input source ID
    if let inputMethodID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
        return Unmanaged<CFString>.fromOpaque(inputMethodID).takeUnretainedValue() as String
    }

    return nil
}

/// 마지막으로 쓰던 라틴 자판으로 전환한다.
///
/// 되돌아오는 방향(라틴 → 팥알)은 CJKV 입력기로 들어가는 전환이라 `TISSelectInputSource`가
/// 간헐적으로 실패한다. 그 방향은 시스템 한/영 키에 맡기고 나가는 방향만 다룬다.
/// 대상 자판은 macOS가 관리하는 "가장 최근에 쓴 ASCII 자판"이므로 우선순위 목록을 두지 않는다.
/// - Returns: 전환에 성공하면 true, 돌아갈 라틴 자판이 없거나 TIS가 거부하면 false
@discardableResult
func selectLatinInputSource() -> Bool {
    // 팥알은 ASCII 자판이 아니므로 이 API는 팥알이 아닌 직전 라틴 자판을 돌려준다
    guard let source = TISCopyCurrentASCIICapableKeyboardInputSource()?.takeRetainedValue() else {
        return false
    }

    return TISSelectInputSource(source) == noErr
}

func getInputLayoutID(id: String) -> LayoutName {
    switch id {
    case "com.soomtong.inputmethod.3-p3":
        return LayoutName.HAN3_P3
    case "com.soomtong.inputmethod.shin3-p2":
        return LayoutName.HAN3_SHIN_P2
    case "com.soomtong.inputmethod.shin3-pcs":
        return LayoutName.HAN3_SHIN_PCS

    default:
        return LayoutName.HAN3_SHIN_PCS
    }
}

func getCurrentProjectVersion() -> String? {
    // Retrieve the build number from the Info.plist
    return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
}

func getMarketingVersion() -> String? {
    // Retrieve the marketing version from the Info.plist
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
}

// function returns char: Int map with sequenced number from 0
func generateOffsetDictionary<T: Hashable>(_ array: [T]) -> [T: Int] {
    var map: [T: Int] = [:]
    for (index, key) in array.enumerated() {
        map[key] = index
    }
    return map
}
