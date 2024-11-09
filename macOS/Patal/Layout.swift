//
//  Layout.swift
//  Patal
//
//  Created by dp on 11/9/24.
//

import Foundation

struct Han3ShinPcsLayout {
    let chosungMap: [String: 초성] = [
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
}

// todo: 클래스나 구조체로 묶어야겠지?
let defaultLayout = Han3ShinPcsLayout()

func pickChosung(char: String) -> String? {
    guard let chosung = defaultLayout.chosungMap[char] else {
        return nil
    }
    
    let utf16CodeUnits: [unichar] = [chosung.rawValue]
    return String(utf16CodeUnits: utf16CodeUnits, count: utf16CodeUnits.count)
}
