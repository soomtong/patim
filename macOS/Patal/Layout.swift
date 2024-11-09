//
//  Layout.swift
//  Patal
//
//  Created by dp on 11/9/24.
//

import Foundation

enum 초성: unichar {
    case 기역 = 0x1100
}

let layoutMap = [
    "k": 초성.기역
]

func isChosung(char: String) -> Bool {
    return true
}

func pickChosung(char: String) -> String? {
    guard let chosung = layoutMap[char] else {
        return nil
    }
    let utf16CodeUnits: [unichar] = [chosung.rawValue]
    return String(utf16CodeUnits: utf16CodeUnits, count: utf16CodeUnits.count)
}
