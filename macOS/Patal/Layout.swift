//
//  Layout.swift
//  Patal
//
//  Created by dp on 11/9/24.
//

import Foundation

protocol Chosung {
    func pickChosung(by char: String) -> unichar?
}

protocol Jungsung {
    func pickJungsung(by char: String) -> unichar?
}

struct Han3ShinPcsLayout: Chosung {
    let logger = CustomLogger(category: "Han3ShinPcsLayout")

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

    let jungsungMap: [String: 중성] = [
        "f": 중성.아,
        "e": 중성.애,
        "w": 중성.야,
        "q": 중성.얘,
        "t": 중성.여,
        "s": 중성.예,
        "v": 중성.오,
        "pf": 중성.와,
        "pe": 중성.왜,
        "pd": 중성.외,
        "x": 중성.요,
        "b": 중성.우,
        "or": 중성.워,
        "oc": 중성.웨,
        "od": 중성.위,
        "a": 중성.유,
        "g": 중성.으,
        "z": 중성.의,
        "d": 중성.이,
    ]

    func pickChosung(by char: String) -> unichar? {
        guard let chosung = self.chosungMap[char] else {
            return nil
        }
        
        logger.debug("초성: \(chosung.rawValue)")
        return chosung.rawValue
    }

    func pickJungsung(by char: String) -> unichar? {
        guard let jungsung = self.jungsungMap[char] else {
            return nil
        }

        logger.debug("중성: \(jungsung.rawValue)")
        return jungsung.rawValue
    }
}
