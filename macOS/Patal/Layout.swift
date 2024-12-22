//
//  Layout.swift
//  Patal
//
//  Created by dp on 11/9/24.
//

import Foundation

/// 지원하는 레이아웃: InfoPlist 파일 참고
enum Layout: String {
    case HAN3_SHIN_PCS = "InputmethodHan3ShinPCS"
    case HAN3_SHIN_P2 = "InputmethodHan3ShinP2"
}

protocol HangulAutomata {
    func pickChosung(by char: String) -> unichar?
    func pickJungsung(by char: String) -> unichar?
    func pickJongsung(by char: String) -> unichar?
}

struct Han3ShinPcsLayout: HangulAutomata {
    let logger = CustomLogger(category: "Han3ShinPcsLayout")

    let chosungMap: [String: 초성] = [
        "k": 초성.기역,
        "kk": 초성.쌍기역,
        "kkk": 초성.키읔,
        "h": 초성.니은,
        "u": 초성.디귿,
        "uu": 초성.쌍디귿,
        "y": 초성.리을,
        "i": 초성.미음,
        ";": 초성.비읍,
        ";;": 초성.쌍비읍,
        "n": 초성.시옷,
        "nn": 초성.쌍시옷,
        "j": 초성.이응,
        "l": 초성.지읒,
        "ll": 초성.쌍지읒,
        "o": 초성.치읓,
        ",": 초성.티긑,
        ".": 초성.키읔,
        "p": 초성.피읖,
        "m": 초성.히읗,
    ]

    let jungsungMap: [String: 중성] = [
        "f": 중성.아,
        "e": 중성.애,
        "w": 중성.야,
        "q": 중성.얘,
        "r": 중성.어,
        "c": 중성.에,
        "t": 중성.여,
        "s": 중성.예,
        "v": 중성.오,
        "p": 중성.오,
        "pf": 중성.와,
        "vf": 중성.와,
        "pe": 중성.왜,
        "ve": 중성.왜,
        "pd": 중성.외,
        "vd": 중성.외,
        "x": 중성.요,
        "b": 중성.우,
        "o": 중성.우,
        "or": 중성.워,
        "br": 중성.워,
        "oc": 중성.웨,
        "bc": 중성.웨,
        "od": 중성.위,
        "bd": 중성.위,
        "a": 중성.유,
        "g": 중성.으,
        "z": 중성.의,
        "gd": 중성.의,
        "d": 중성.이,
    ]

    let jongsungMap: [String: 종성] = [
        "c": 종성.기역,
        "C": 종성.기역,
        "cc": 종성.쌍기역,
        "CC": 종성.쌍기역,
        "cq": 종성.기역시옷,
        "s": 종성.니은,
        "S": 종성.니은,
        "sv": 종성.니은지읒,
        "sd": 종성.니은히읗,
        "g": 종성.디귿,
        "G": 종성.디귿,
        "w": 종성.리을,
        "W": 종성.리을,
        "wc": 종성.리을기역,
        "WC": 종성.리을기역,
        "wz": 종성.리을미음,
        "we": 종성.리을비읍,
        "wq": 종성.리을시옷,
        "wr": 종성.리을티긑,
        "wf": 종성.리을피읖,
        "wd": 종성.리을히읗,
        "z": 종성.미음,
        "Z": 종성.미음,
        "e": 종성.비읍,
        "E": 종성.비읍,
        "q": 종성.시옷,
        "Q": 종성.시옷,
        "qq": 종성.쌍시옷,
        "x": 종성.쌍시옷,
        "X": 종성.쌍시옷,
        "a": 종성.이응,
        "A": 종성.이응,
        "v": 종성.지읒,
        "V": 종성.지읒,
        "b": 종성.치읓,
        "B": 종성.치읓,
        "t": 종성.키엌,
        "T": 종성.키엌,
        "r": 종성.티긑,
        "R": 종성.티긑,
        "f": 종성.피읖,
        "F": 종성.피읖,
        "d": 종성.히흫,
        "D": 종성.히흫,
    ]

    func pickChosung(by char: String) -> unichar? {
        guard let chosung = self.chosungMap[char] else {
            return nil
        }

        return chosung.rawValue
    }

    func pickJungsung(by char: String) -> unichar? {
        guard let jungsung = self.jungsungMap[char] else {
            return nil
        }

        return jungsung.rawValue
    }

    func pickJongsung(by char: String) -> unichar? {
        guard let jongsung = self.jongsungMap[char] else {
            return nil
        }

        return jongsung.rawValue
    }
}
