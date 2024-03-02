//
//  InputKey.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation

class InputTextKey {
    let logger = CustomLogger(category: "InputTextKey")

    var string: String
    var keyCode: Int
    var flags: Int

    // 키코드 목록 https://eastmanreference.com/complete-list-of-applescript-key-codes
    private let cmdFlags = 1_048_576
    private let ctrlFlags = 262144
    private let optFlags = 524288
    private let shiftFlags = 131072

    private let escKeyCode = 53

    init(string: String, keyCode: Int, flags: Int) {
        logger.debug("입력키 처리 클래스 초기화")
        self.string = string
        self.keyCode = keyCode
        self.flags = flags
    }

    func bind(string: String, keyCode: Int, flags: Int) {
        // 특수 키 - ESC ENTER SHIFT 등의 입력을 위해 keyCode 를 받아야 함
        logger.debug("입력된 문자: \(String(describing: string)), \(keyCode), \(flags)")

        self.string = string
        self.keyCode = keyCode
        self.flags = flags
    }

    func isEscaped() -> Bool {
        if self.keyCode == self.escKeyCode && self.flags == 0 {
            return true
        }
        return false
    }

    func getChar() -> String? {
        return Optional("ㅎ하한글?횂!")
    }
}
