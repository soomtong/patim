//
//  HangulCode.swift
//  Patal
//
//  Created by dp on 11/9/24.
//

import Foundation

enum 자음: unichar {
    case 채움 = 0x115F
    // 현대 닿소리
    case 기역 = 0x3131
    case 쌍기역 = 0x3132
    case 기역시옷 = 0x3133
    case 니은 = 0x3134
    // ...
}

enum 모음: unichar {
    case 채움 = 0x1160
    // 현대 홑소리
    case 아 = 0x314F
    case 애 = 0x3150
    case 야 = 0x3151
    // ...
}

enum 그외: unichar {
    case 채움문자 = 0x3164
}

enum 초성: unichar {
    case 기역 = 0x1100
    case 쌍기역 = 0x1101
    case 니은 = 0x1102
    case 디귿 = 0x1103
    case 쌍디귿 = 0x1104
    case 리을 = 0x1105
    case 미음 = 0x1106
    case 비읍 = 0x1107
    case 쌍비읍 = 0x1108
    case 시옷 = 0x1109
    case 쌍시옷 = 0x110A
    case 이응 = 0x110B
    case 지읒 = 0x110C
    case 쌍지읒 = 0x110D
    case 치읓 = 0x110E
    case 키읔 = 0x110F
    case 티긑 = 0x1110
    case 피읖 = 0x1111
    case 히읗 = 0x1112
    // ...
    case 채움 = 0x115F
}

enum 중성: unichar {
    case 채움 = 0x1160
    case 아 = 0x1161
    case 애 = 0x1162
    case 야 = 0x1163
    case 얘 = 0x1164
    case 어 = 0x1165
    case 에 = 0x1166
    case 여 = 0x1167
    case 예 = 0x1168
    case 오 = 0x1169
    case 와 = 0x116A
    case 왜 = 0x116B
    case 외 = 0x116C
    case 요 = 0x116D
    case 우 = 0x116E
    case 워 = 0x116F
    case 웨 = 0x1170
    case 위 = 0x1171
    case 유 = 0x1172
    case 으 = 0x1173
    case 의 = 0x1174
    case 이 = 0x1175
    case 아래아 = 0x119E
    case 아래어 = 0x119F
    case 아래우 = 0x11A0
    case 아래애 = 0x11A1
}

enum 종성: unichar {
    case 없음 = 0x0000
    case 기역 = 0x11A8
    case 쌍기역 = 0x11A9
    case 기역시옷 = 0x11AA
    case 니은 = 0x11AB
    case 니은지읒 = 0x11AC
    case 니은히읗 = 0x11AD
    case 디귿 = 0x11AE
    case 리을 = 0x11AF
    case 리을기역 = 0x11B0
    case 리을미음 = 0x11B1
    case 리을비읍 = 0x11B2
    case 리을시옷 = 0x11B3
    case 리을티긑 = 0x11B4
    case 리을피읖 = 0x11B5
    case 리을히읗 = 0x11B6
    case 미음 = 0x11B7
    case 비읍 = 0x11B8
    case 비읍시옷 = 0x11B9
    case 시옷 = 0x11BA
    case 쌍시옷 = 0x11BB
    case 이응 = 0x11BC
    case 지읒 = 0x11BD
    case 치읓 = 0x11BE
    case 키엌 = 0x11BF
    case 티긑 = 0x11C0
    case 피읖 = 0x11C1
    case 히흫 = 0x11C2
}
