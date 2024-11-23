//
//  HangulCode.swift
//  Patal
//
//  Created by dp on 11/9/24.
//

import Foundation

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
    case 쌍시옷 = 0x110a
    case 이응 = 0x110b
    case 지읒 = 0x110c
    case 쌍지읒 = 0x110d
    case 치읓 = 0x110e
    case 키읔 = 0x110f
    case 티긑 = 0x1110
    case 피읖 = 0x1111
    case 히읗 = 0x1112
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
    case 와 = 0x116a
    case 왜 = 0x116b
    case 외 = 0x116c
    case 요 = 0x116d
    case 우 = 0x116e
    case 워 = 0x116f
    case 웨 = 0x1170
    case 위 = 0x1171
    case 유 = 0x1172
    case 으 = 0x1173
    case 의 = 0x1174
    case 이 = 0x1175
}

enum 종성: unichar {
    case 기역 = 0x11a8
    case 쌍기역 = 0x11a9
    case 기역시옷 = 0x11aa
    case 니은 = 0x11ab
    case 니은지읒 = 0x11ac
    case 니은히읗 = 0x11ad
    case 디귿 = 0x11ae
    case 리을 = 0x11af
    case 리을기역 = 0x11b0
    case 리을미음 = 0x11b1
    case 리을비읍 = 0x11b2
    case 리을시옷 = 0x11b3
    case 리을티긑 = 0x11b4
    case 리을피읖 = 0x11b5
    case 리을히읗 = 0x11b6
    case 미음 = 0x11b7
    case 비읍 = 0x11b8
    case 비읍시옷 = 0x11b9
    case 시옷 = 0x11ba
    case 쌍시옷 = 0x11bb
    case 이응 = 0x11bc
    case 지읒 = 0x11bd
    case 치읓 = 0x11be
    case 키엌 = 0x11bf
    case 티긑 = 0x11c0
    case 피읖 = 0x11c1
    case 히흫 = 0x11c2
}
