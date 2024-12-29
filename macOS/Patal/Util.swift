//
//  Util.swift
//  Patal
//
//  Created by dp on 12/2/24.
//

import Carbon
import Foundation

func keepUserTraits(traitKey: String, traitValue: String) {
    UserDefaults.standard.set(traitValue, forKey: traitKey)
    UserDefaults.standard.synchronize()
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

func getInputLayoutID(id: String) -> LayoutName {
    switch id {
    case "com.soomtong.inputmethod.3-p2":
        return LayoutName.HAN3_P2
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

// function returns char: Int map with sequenced number from 0
func generateOffsetDictionary<T: Hashable>(_ array: [T]) -> [T: Int] {
    var map: [T: Int] = [:]
    for (index, key) in array.enumerated() {
        map[key] = index
    }
    return map
}
