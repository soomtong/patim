//
//  Layout.swift
//  Patal
//
//  Created by dp on 11/9/24.
//

import Foundation

enum 초성: unichar {
    case 기역 = 0x1100
    case 쌍기역 = 0x1101
    case 니은 = 0x1102
    case 디귿 = 0x1103
    case 쌍디귿 = 0x1104
    case 리을 = 0x1105
    case 미음 = 0x1106
    case 비읍 = 0x1107
    case 쌍비읍 = 0x1108
    case 시옷 = 0x1109
    case 쌍시옷 = 0x110a
    case 이응 = 0x110b
    case 지읒 = 0x110c
    case 쌍지읒 = 0x110d
    case 치읓 = 0x110e
    case 키읔 = 0x110f
    case 티긑 = 0x1110
    case 피읖 = 0x1111
    case 히읗 = 0x1112
}

let layoutMap = [
    "k": 초성.기역,
    "h": 초성.니은,
    "u": 초성.디귿,
    "y": 초성.리을,
    "i": 초성.미음,
    ";": 초성.비읍,
    "n": 초성.시옷,
    "j": 초성.이응,
    "l": 초성.지읒,
    "o": 초성.치읓,
    ",": 초성.키읔,
    ".": 초성.티긑,
    "p": 초성.피읖,
    "m": 초성.히읗,
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
