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

func pickChosung(char: String) -> 초성? {
    return layoutMap[char]
}
