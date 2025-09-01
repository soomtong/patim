//
//  KeyCodeMapper.swift
//  Patal
//
//  Created by dp on 09/01/2025.
//

import Foundation

/// 물리적 키코드를 한글 입력용 문자로 변환하는 매퍼
/// 라틴 자판(QWERTY, Colemak, Dvorak 등) 독립적인 한글 입력을 위한 핵심 컴포넌트
/// eastmanreference.com의 키코드 정보를 기반으로 구현
class KeyCodeMapper {

    /// ANSI 키보드 레이아웃 기준 물리적 키코드 매핑
    /// 참조: https://eastmanreference.com/complete-list-of-applescript-key-codes
    private static let physicalKeyMap: [Int: String] = [
        // 숫자 행 (Number row)
        18: "1",  // ! 1
        19: "2",  // @ 2
        20: "3",  // # 3
        21: "4",  // $ 4
        23: "5",  // % 5
        22: "6",  // ^ 6
        26: "7",  // & 7
        28: "8",  // * 8
        25: "9",  // ( 9
        29: "0",  // ) 0
        27: "-",  // _ -
        24: "=",  // + =

        // 상단 행 (Top row)
        12: "q",  // Q
        13: "w",  // W
        14: "e",  // E
        15: "r",  // R
        17: "t",  // T
        16: "y",  // Y
        32: "u",  // U
        34: "i",  // I
        31: "o",  // O
        35: "p",  // P
        33: "[",  // { [
        30: "]",  // } ]
        42: "\\",  // | \

        // 중간 행 (Home row)
        0: "a",  // A
        1: "s",  // S
        2: "d",  // D
        3: "f",  // F
        5: "g",  // G
        4: "h",  // H
        38: "j",  // J
        40: "k",  // K
        37: "l",  // L
        41: ";",  // : ;
        39: "'",  // " '

        // 하단 행 (Bottom row)
        6: "z",  // Z
        7: "x",  // X
        8: "c",  // C
        9: "v",  // V
        11: "b",  // B
        45: "n",  // N
        46: "m",  // M
        43: ",",  // < ,
        47: ".",  // > .
        44: "/",  // ? /

        // 기타 키들
        50: "`",  // ~ `
        49: " ",  // Space
    ]

    /// Shift 상태에서의 키코드 매핑
    private static let shiftKeyMap: [Int: String] = [
        18: "!",  // ! 1
        19: "@",  // @ 2
        20: "#",  // # 3
        21: "$",  // $ 4
        23: "%",  // % 5
        22: "^",  // ^ 6
        26: "&",  // & 7
        28: "*",  // * 8
        25: "(",  // ( 9
        29: ")",  // ) 0
        27: "_",  // _ -
        24: "+",  // + =

        12: "Q",  // Q
        13: "W",  // W
        14: "E",  // E
        15: "R",  // R
        17: "T",  // T
        16: "Y",  // Y
        32: "U",  // U
        34: "I",  // I
        31: "O",  // O
        35: "P",  // P
        33: "{",  // { [
        30: "}",  // } ]
        42: "|",  // | \

        0: "A",  // A
        1: "S",  // S
        2: "D",  // D
        3: "F",  // F
        5: "G",  // G
        4: "H",  // H
        38: "J",  // J
        40: "K",  // K
        37: "L",  // L
        41: ":",  // : ;
        39: "\"",  // " '

        6: "Z",  // Z
        7: "X",  // X
        8: "C",  // C
        9: "V",  // V
        11: "B",  // B
        45: "N",  // N
        46: "M",  // M
        43: "<",  // < ,
        47: ">",  // > .
        44: "?",  // ? /

        50: "~",  // ~ `
    ]

    /// 물리적 키코드를 한글 입력용 문자로 변환
    /// - Parameters:
    ///   - keyCode: 물리적 키코드
    ///   - modifiers: 수정자 키 플래그
    /// - Returns: 한글 입력에 사용할 문자열 (라틴 자판 독립적)
    static func mapKeyCodeToHangulChar(keyCode: Int, modifiers: Int) -> String? {
        let isShiftPressed = (modifiers & ModifierCode.SHIFT.rawValue) != 0

        if isShiftPressed {
            return shiftKeyMap[keyCode] ?? physicalKeyMap[keyCode]
        } else {
            return physicalKeyMap[keyCode]
        }
    }

    /// 키코드가 한글 입력에 사용 가능한 키인지 확인
    /// - Parameter keyCode: 확인할 키코드
    /// - Returns: 한글 입력 가능 여부
    static func isHangulInputKey(keyCode: Int) -> Bool {
        return physicalKeyMap[keyCode] != nil
    }

    /// 디버깅용: 키코드 정보를 문자열로 반환
    /// - Parameters:
    ///   - keyCode: 키코드
    ///   - modifiers: 수정자 플래그
    /// - Returns: 디버그 정보 문자열
    static func debugKeyInfo(keyCode: Int, modifiers: Int) -> String {
        let char = mapKeyCodeToHangulChar(keyCode: keyCode, modifiers: modifiers) ?? "unknown"
        let isShift = (modifiers & ModifierCode.SHIFT.rawValue) != 0
        return "keyCode: \(keyCode), char: '\(char)', shift: \(isShift)"
    }
}
