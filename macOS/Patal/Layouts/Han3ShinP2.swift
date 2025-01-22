//
//  Han3ShinP2.swift
//  Patal
//
//  Created by dp on 12/22/24.
//

import Foundation

/** 자판 배열 소개
 신세벌식 P 자판 https://pat.im/1110
 옛한글 조합은 추가개발이 필요함
 */

/// enum LayoutName 의 createLayoutInstance 조합기 이름과 같아야 합니다.
struct Han3ShinP2Layout: HangulAutomata {
    let availableTraits: Set<LayoutTrait> = [LayoutTrait.아래아, LayoutTrait.글자단위삭제, LayoutTrait.화살표]
    var traits: Set<LayoutTrait> = []

    let chosungMap: [String: 초성] = [
        "k": 초성.기역,
        "kk": 초성.쌍기역,
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
        "'": 초성.티긑,
        "/": 초성.키읔,
        "p": 초성.피읖,
        "m": 초성.히읗,
    ]

    let jungsungMap: [String: 중성] = [
        "f": 중성.아, "F": 중성.아,
        "e": 중성.애, "E": 중성.애,
        "w": 중성.야, "W": 중성.야,
        "q": 중성.얘, "Q": 중성.얘,
        "r": 중성.어, "R": 중성.어,
        "c": 중성.에, "C": 중성.에,
        "t": 중성.여, "T": 중성.여,
        "s": 중성.예, "S": 중성.예,
        "v": 중성.오, "V": 중성.오,
        "/": 중성.오,
        "/f": 중성.와, "/F": 중성.와,
        "/e": 중성.왜, "/E": 중성.왜,
        "/d": 중성.외, "/D": 중성.외,
        "x": 중성.요, "X": 중성.요,
        "b": 중성.우, "B": 중성.우,
        "o": 중성.우,
        "or": 중성.워, "oR": 중성.워,
        "oc": 중성.웨, "oC": 중성.웨,
        "od": 중성.위, "oD": 중성.위,
        "a": 중성.유, "A": 중성.유,
        "g": 중성.으, "G": 중성.으,
        "i": 중성.으,
        "id": 중성.의, "iD": 중성.의,
        "d": 중성.이, "D": 중성.이,
        /* 아래아 대신 사용함 */
        "z": 중성.의, "Z": 중성.의,
        "p": 중성.오,
        "pf": 중성.와, "pF": 중성.와,
        "pe": 중성.왜, "pE": 중성.왜,
        "pd": 중성.외, "pD": 중성.외,
    ]
    let jungsungMapWith아래아: [String: 중성] = [
        "z": 중성.아래아, "Z": 중성.아래아,
        "p": 중성.아래아,
        "pr": 중성.아래어,
        "pb": 중성.아래우,
        "pd": 중성.아래애,
    ]

    let jongsungMap: [String: 종성] = [
        "c": 종성.기역,
        "cc": 종성.쌍기역,
        "cq": 종성.기역시옷,
        "s": 종성.니은,
        "sv": 종성.니은지읒,
        "sd": 종성.니은히읗,
        "g": 종성.디귿,
        "w": 종성.리을,
        "wc": 종성.리을기역,
        "wz": 종성.리을미음,
        "we": 종성.리을비읍,
        "wq": 종성.리을시옷,
        "wr": 종성.리을티긑,
        "wf": 종성.리을피읖,
        "wd": 종성.리을히읗,
        "z": 종성.미음,
        "e": 종성.비읍,
        "eq": 종성.비읍시옷,
        "q": 종성.시옷,
        "qq": 종성.쌍시옷,
        "x": 종성.쌍시옷,
        "a": 종성.이응,
        "v": 종성.지읒,
        "b": 종성.치읓,
        "t": 종성.키읔,
        "r": 종성.티긑,
        "f": 종성.피읖,
        "d": 종성.히흫,
    ]

    let nonSyllableMap: [String: String] = [
        "Y": "✕",
        "U": "○",
        "I": "△",
        "O": "※",
        "P": ";",
        "H": "□",
        "J": "\'",
        "K": "\"",
        "L": "·",
        "\"": "/",
        "N": "―",
        "M": "…",
    ]

    let nonSyllableMapWith쉬운화살표: [String: String] = [
        "Y": "✕",
        "U": "◯",
        "I": "∆",
        "H": "☐",
        "N": "←",
        "M": "→",
    ]

    func pickJungsung(by char: String) -> unichar? {
        if has아래아 {
            if let jungsung = jungsungMapWith아래아[char] {
                return jungsung.rawValue
            }
        }

        guard let jungsung = jungsungMap[char] else {
            return nil
        }

        return jungsung.rawValue
    }

    func pickNonSyllable(by char: String) -> String? {
        if has화살표 {
            if let nonSyllable = nonSyllableMapWith쉬운화살표[char] {
                return nonSyllable
            }
        }

        guard let nonSyllable = nonSyllableMap[char] else {
            return nil
        }

        return nonSyllable
    }
}
