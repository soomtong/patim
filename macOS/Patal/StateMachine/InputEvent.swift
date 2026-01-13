//
//  InputEvent.swift
//  Patal
//
//  FSM 입력 이벤트 정의
//

import Foundation

/// 자모 타입 구분
enum JamoType: Equatable {
    case chosung(초성)
    case jungsung(중성)
    case jongsung(종성)
    /// 3-벌식에서 초성/종성 공유 키 (갈마들이)
    case chosungOrJongsung(chosung: 초성, jongsung: 종성)
}

/// 자모 입력 정보
struct JamoInput: Equatable {
    let rawChar: String
    let jamoType: JamoType
    let codePoint: unichar

    init(rawChar: String, jamoType: JamoType, codePoint: unichar) {
        self.rawChar = rawChar
        self.jamoType = jamoType
        self.codePoint = codePoint
    }

    /// 초성 입력 생성
    static func chosung(_ cho: 초성, rawChar: String) -> JamoInput {
        JamoInput(rawChar: rawChar, jamoType: .chosung(cho), codePoint: cho.rawValue)
    }

    /// 중성 입력 생성
    static func jungsung(_ jung: 중성, rawChar: String) -> JamoInput {
        JamoInput(rawChar: rawChar, jamoType: .jungsung(jung), codePoint: jung.rawValue)
    }

    /// 종성 입력 생성
    static func jongsung(_ jong: 종성, rawChar: String) -> JamoInput {
        JamoInput(rawChar: rawChar, jamoType: .jongsung(jong), codePoint: jong.rawValue)
    }
}

/// FSM 입력 이벤트
enum InputEvent: Equatable {
    /// 자모 입력
    case jamo(JamoInput)

    /// 백스페이스 - 마지막 자모 삭제
    case backspace

    /// 조합 확정 - Enter, 비한글 입력 등
    case commit

    /// 조합 취소 - 포커스 변경, 커서 이동, ESC
    case cancel
}
