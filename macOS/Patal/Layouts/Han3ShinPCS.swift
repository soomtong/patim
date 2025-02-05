//
//  Han3ShinPCS.swift
//  Patal
//
//  Created by dp on 12/22/24.
//

import Foundation

/** 자판 배열 소개
 50% 미만 배열은 우측 새끼손가락으로 누르는 키가 없는 경우가 있음
 그런 키보드를 위한 배열을 구성
 */

/// enum LayoutName 의 createLayoutInstance 조합기 이름과 같아야 합니다.
struct Han3ShinPcsLayout: HangulAutomata {
    let availableTraits: Set<LayoutTrait> = [LayoutTrait.수정기호, LayoutTrait.글자단위삭제]
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
        ",": 초성.티긑,
        ".": 초성.키읔,
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
        "p": 중성.오,
        "pf": 중성.와, "pF": 중성.와,
        "pe": 중성.왜, "pE": 중성.왜,
        "pd": 중성.외, "pD": 중성.외,
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
        "z": 중성.의, "Z": 중성.의,
        "d": 중성.이, "D": 중성.이,
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
        "Y": "{",
        "U": "}",
        "I": "\'",
        "O": "\"",
        "P": ";",
        "H": "[",
        "J": "]",
        "K": ",",
        "L": ".",
        "N": "(",
        "M": ")",
    ]

    let nonSyllableMapWith수정기호: [String: String] = [
        "N": "←",
        "M": "→",
    ]

    func pickNonSyllable(by char: String) -> String? {
        if has수정기호 {
            if let nonSyllable = nonSyllableMapWith수정기호[char] {
                return nonSyllable
            }
        }

        guard let nonSyllable = nonSyllableMap[char] else {
            return nil
        }

        return nonSyllable
    }

    let chosungReverseIndex: [String] = [
        "k", "kk", "h", "u", "uu", "y", "i", ";", ";;",
        "n", "nn", "j", "l", "ll", "o", "'", "/", "p", "m",
    ]

    func getChosungRawString(by chosung: 초성) -> String {
        return chosungReverseIndex[chosungMapOffset[chosung]!]
    }

    let jungsungReverseIndex: [String] = [
        "f", "e", "w", "q", "r", "c", "t", "s", "v", "pf",
        "pe", "pd", "x", "b", "o", "or", "oc", "od", "a",
        "g", "g", "i", "id", "z", "d",
    ]

    func getJungsungRawString(by jungsung: 중성) -> String {
        return jungsungReverseIndex[jungsungMapOffset[jungsung]!]
    }

    let jongsungReverseIndex: [String] = [
        "c", "cc", "cq", "s", "sv", "sd", "g", "w", "wc", "wz",
        "we", "wq", "wr", "wf", "wd", "z", "e", "eq", "q",
        "x", "a", "v", "b", "t", "r", "f", "d",
    ]

    func getJongsungRawString(by jongsung: 종성) -> String {
        return jongsungReverseIndex[jongsungMapOffset[jongsung]!]
    }
}
