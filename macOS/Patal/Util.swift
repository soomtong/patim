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

// MARK: - 영문 자판 전환

/// 영문 입력 소스 ID 우선순위
private let englishInputSourcePriority = [
    // 기본 영문 자판
    "com.apple.keylayout.ABC",
    "com.apple.keylayout.USExtended",  // ABC – Extended
    "com.apple.keylayout.US",
    "com.apple.keylayout.British",
    "com.apple.keylayout.British-PC",
    "com.apple.keylayout.Australian",
    "com.apple.keylayout.Canadian",
    "com.apple.keylayout.Irish",
    // 대안 자판
    "com.apple.keylayout.Colemak",
    "com.apple.keylayout.Dvorak",
    "com.apple.keylayout.DVORAK-QWERTYCMD",  // Dvorak – QWERTY ⌘
    "com.apple.keylayout.Dvorak-Left",
    "com.apple.keylayout.Dvorak-Right",
]

/// 설치된 영문 자판 중 우선순위가 가장 높은 것으로 전환
/// - Returns: 전환 성공 여부
func switchToEnglishInputSource() -> Bool {
    // 현재 활성화된 입력 소스 목록 가져오기
    let properties: [CFString: Any] = [
        kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource!,
        kTISPropertyInputSourceIsSelectCapable: true,
    ]

    guard
        let sources = TISCreateInputSourceList(properties as CFDictionary, false)?
            .takeUnretainedValue() as? [TISInputSource]
    else {
        return false
    }

    // 설치된 입력 소스 ID 목록 추출
    let installedIDs = sources.compactMap { source -> String? in
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    // 우선순위에 따라 영문 자판 찾기
    for targetID in englishInputSourcePriority {
        if installedIDs.contains(targetID) {
            return selectInputSource(withID: targetID)
        }
    }

    return false
}

private func selectInputSource(withID sourceID: String) -> Bool {
    let properties: [CFString: Any] = [kTISPropertyInputSourceID: sourceID]

    guard
        let sources = TISCreateInputSourceList(properties as CFDictionary, false)?
            .takeUnretainedValue() as? [TISInputSource],
        let source = sources.first
    else {
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
