//
//  Han3P3.swift
//  Patal
//
//  Created by dp on 12/25/24.
//

import Foundation

/** 자판 배열 소개
 갈마들이 공세벌식 자판 3-P 자판안 https://pat.im/1128
 */

/// enum LayoutName 의 createLayoutInstance 조합기 이름과 같아야 합니다.
struct Han3P3Layout: HangulAutomata {
    let availableTraits: Set<LayoutTrait> = [LayoutTrait.모아주기, LayoutTrait.두줄숫자, LayoutTrait.글자단위삭제]
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
        "0": 초성.키읔,
        "p": 초성.피읖,
        "m": 초성.히읗,
    ]

    let jungsungMap: [String: 중성] = [
        "f": 중성.아,
        "t": 중성.애,
        "6": 중성.야,
        "T": 중성.얘,
        "r": 중성.어,
        "c": 중성.에,
        "e": 중성.여,
        "7": 중성.예,
        "v": 중성.오,
        "/": 중성.오,
        "/f": 중성.와,
        "/e": 중성.왜,
        "/d": 중성.외,
        "4": 중성.요,
        "b": 중성.우,
        "9": 중성.우,
        "9r": 중성.워,
        "9c": 중성.웨,
        "9d": 중성.위,
        "5": 중성.유,
        "g": 중성.으,
        "8": 중성.으,
        "8d": 중성.의,
        "d": 중성.이,
    ]

    let jongsungMap: [String: 종성] = [
        "x": 종성.기역,
        "X": 종성.쌍기역,
        "xx": 종성.쌍기역,
        "xq": 종성.기역시옷,
        "s": 종성.니은,
        "sv": 종성.니은지읒,
        "sd": 종성.니은히읗,
        "S": 종성.니은히읗,
        "c": 종성.디귿,
        "w": 종성.리을,
        "W": 종성.리을기역,
        "wx": 종성.리을기역,
        "Z": 종성.리을미음,
        "wz": 종성.리을미음,
        "w3": 종성.리을비읍,
        "wq": 종성.리을시옷,
        "we": 종성.리을티긑,
        "wf": 종성.리을피읖,
        "wd": 종성.리을히읗,
        "Q": 종성.리을히읗,
        "z": 종성.미음,
        "3": 종성.비읍,
        "A": 종성.비읍시옷,
        "3q": 종성.비읍시옷,
        "q": 종성.시옷,
        "2": 종성.쌍시옷,
        "qq": 종성.쌍시옷,
        "a": 종성.이응,
        "v": 종성.지읒,
        "r": 종성.치읓,
        "1": 종성.키읔,
        "e": 종성.티긑,
        "f": 종성.피읖,
        "d": 종성.히흫,
    ]

    let nonSyllableMap: [String: String] = [
        "Y": "/",
        "U": "7",
        "I": "8",
        "O": "9",
        "P": ";",
        "G": "<",
        "H": "\'",
        "J": "4",
        "K": "5",
        "L": "6",
        "B": ">",
        "N": "0",
        "M": "1",
        "<": "2",
        ">": "3",
    ]

    let nonSyllableMapWith두줄숫자: [String: String] = [
        "Y": "5",
        "U": "6",
        "I": "7",
        "O": "8",
        "P": "9",
        "G": ":",
        "H": "0",
        "J": "1",
        "K": "2",
        "L": "3",
        ":": "4",
        "\"": "/",
        "B": ";",
        "N": "\'",
        "M": "\"",
    ]

    func pickNonSyllable(by char: String) -> String? {
        if has두줄숫자 {
            if let nonSyllable = nonSyllableMapWith두줄숫자[char] {
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
        "n", "nn", "j", "l", "ll", "o", "'", "0", "p", "m",
    ]

    func getChosungRawString(by chosung: 초성) -> String {
        return chosungReverseIndex[chosungMapOffset[chosung]!]
    }

    let jungsungReverseIndex: [String] = [
        "f", "t", "6", "T", "r", "c", "e", "7", "/",
        "/f", "/e", "/d", "4", "9", "9r", "9c", "9d",
        "5", "8", "8d", "d",
    ]

    func getJungsungRawString(by jungsung: 중성) -> String {
        return jungsungReverseIndex[jungsungMapOffset[jungsung]!]
    }

    let jongsungReverseIndex: [String] = [
        "x", "xx", "xq", "s", "sv", "sd", "S", "c", "w", "wx", "wz", "w3", "wq",
        "we", "wf", "wd", "z", "3", "3q", "q", "2", "a", "v", "r", "1", "e", "f", "d",
    ]

    func getJongsungRawString(by jongsung: 종성) -> String {
        return jongsungReverseIndex[jongsungMapOffset[jongsung]!]
    }
}
