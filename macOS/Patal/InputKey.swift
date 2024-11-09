//
//  InputKey.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation

struct ComposedChar {
    var char: String
    var keyCode: Int
    var flags: Int
}

class InputTextKey {
    let logger = CustomLogger(category: "InputTextKey")

    var string: String
    var keyCode: Int
    var flags: Int

    var buffer: [ComposedChar]

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

        self.buffer = []
    }

    func bind(string: String, keyCode: Int, flags: Int) {
        // 특수 키 - ESC ENTER SHIFT 등의 입력을 위해 keyCode 를 받아야 함
        logger.debug("입력된 문자: \(String(describing: string)), \(keyCode), \(flags)")

        self.string = string
        self.keyCode = keyCode
        self.flags = flags

        let char = ComposedChar(char: self.string, keyCode: self.keyCode, flags: self.flags)
        self.buffer.append(char)
    }

    func isEscaped() -> Bool {
        if self.keyCode == self.escKeyCode && self.flags == 0 {
            // test 용도
            self.buffer.removeAll()
            return true
        }
        return false
    }

    func getComposedChar() -> String? {
        // 입력된 문자열을 작은 버퍼에 담고 조합되는 글자를 반환한다.
        // return Optional("ㅎ하한글?횂!")

        // buffer 의 글자를 확인
        // let keyCodeString = String(self.buffer.last?.keyCode ?? 0)
        // return keyCodeString

        // keyCode 대신 string 을 직접 사용해 보자.
        // 초성이 들어오면 조합 시작
        if let char = self.buffer.first {
            return isChosung(char: char.char) ? "Chosung detected" : "Not a Chosung"
        }
        return nil
    }
}
