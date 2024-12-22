//
//  Util.swift
//  Patal
//
//  Created by dp on 12/2/24.
//

import Foundation
import Carbon

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
