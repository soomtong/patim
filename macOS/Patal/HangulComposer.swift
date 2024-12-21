//
//  HangulComposition.swift
//  Patal
//
//  Created by dp on 12/4/24.
//

import Foundation

// 초성 19조합: ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ
let chosungMap: [초성] = [
    초성.기역, 초성.쌍기역, 초성.니은, 초성.디귿, 초성.쌍디귿, 초성.리을, 초성.미음, 초성.비읍, 초성.쌍비읍, 초성.시옷,
    초성.쌍시옷, 초성.이응, 초성.지읒, 초성.쌍지읒, 초성.치읓, 초성.키읔, 초성.티긑, 초성.피읖, 초성.히읗,
]
let chosungMapOffset: [초성: Int] = generateOffsetDictionary(chosungMap)

// 중성 21조합: ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ
let jungsungMap: [중성] = [
    중성.아, 중성.애, 중성.야, 중성.얘, 중성.어, 중성.에, 중성.여, 중성.예, 중성.오, 중성.와,
    중성.왜, 중성.외, 중성.요, 중성.우, 중성.워, 중성.웨, 중성.위, 중성.유, 중성.으, 중성.의, 중성.이,
]
let jungsungMapOffset: [중성: Int] = generateOffsetDictionary(jungsungMap)

// 종성 28조합: (빈 끝소리) + ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ
let jongsungMap: [종성] = [
    종성.없음, 종성.기역, 종성.쌍기역, 종성.기역시옷, 종성.니은, 종성.니은지읒, 종성.니은히읗, 종성.디귿,
    종성.리을, 종성.리을기역, 종성.리을미음, 종성.리을비읍, 종성.리을시옷, 종성.리을티긑,
    종성.리을피읖, 종성.리을히읗, 종성.미음, 종성.비읍, 종성.비읍시옷, 종성.시옷, 종성.쌍시옷,
    종성.이응, 종성.지읒, 종성.치읓, 종성.키엌, 종성.티긑, 종성.피읖, 종성.히흫,
]
let jongsungMapOffset: [종성: Int] = generateOffsetDictionary(jongsungMap)

let hangulUnicodeOffset = 0xAC00

let chosungOffset19 = chosungMap.count
let jungsungOffset21 = jungsungMap.count
let jongsungOffset28 = jongsungMap.count

struct HangulComposer {
    var chosungPoint: 초성? = nil
    var jungsungPoint: 중성? = nil
    var jongsungPoint: 종성? = nil

    init?(chosungPoint: 초성?, jungsungPoint: 중성?, jongsungPoint: 종성?) {
        // 초성이 없거나 중성이 없는 조합은 배제한다.
        switch (chosungPoint, jungsungPoint, jongsungPoint) {
        case (let chosungPoint?, nil, nil) where chosungMapOffset[chosungPoint] != nil:
            self.chosungPoint = chosungPoint
        case (nil, let jungsungPoint?, nil) where jungsungMapOffset[jungsungPoint] != nil:
            self.jungsungPoint = jungsungPoint
        case (nil, nil, let jongsungPoint?) where jongsungMapOffset[jongsungPoint] != nil:
            self.jongsungPoint = jongsungPoint
        case (let chosungPoint?, let jungsungPoint?, nil)
        where chosungMapOffset[chosungPoint] != nil && jungsungMapOffset[jungsungPoint] != nil:
            self.chosungPoint = chosungPoint
            self.jungsungPoint = jungsungPoint
        // 초성이 없거나 중성이 없는 조합은 배제한다.
        // case (nil, let jungsungPoint?, let jongsungPoint?)
        // where jungsungMapOffset[jungsungPoint] != nil
        //   && jongsungPlusEmptyMapOffset[jongsungPoint] != nil:
        //   self.jungsungPoint = jungsungPoint
        //   self.jongsungPoint = jongsungPoint
        case (let chosungPoint?, let jungsungPoint?, let jongsungPoint?)
        where chosungMapOffset[chosungPoint] != nil && jungsungMapOffset[jungsungPoint] != nil
            && jongsungMapOffset[jongsungPoint] != nil:
            self.chosungPoint = chosungPoint
            self.jungsungPoint = jungsungPoint
            self.jongsungPoint = jongsungPoint
        default:
            return nil
        }
    }

    func getSyllable() -> Character? {
        switch (chosungPoint, jungsungPoint, jongsungPoint) {
        case (nil, nil, nil):
            return nil
        case (let chosung?, nil, nil):
            return Character(UnicodeScalar(chosung.rawValue)!)
        case (nil, let jungsug?, nil):
            return Character(UnicodeScalar(jungsug.rawValue)!)
        case (nil, nil, let jongsung?):
            return Character(UnicodeScalar(jongsung.rawValue)!)
        case (let chosung?, let jungsung?, nil):
            var offset = 0
            if let chosungOffset = chosungMapOffset[chosung] {
                offset += chosungOffset * jungsungOffset21 * jongsungOffset28
            }
            if let jungsungOffset = jungsungMapOffset[jungsung] {
                offset += jungsungOffset * jongsungOffset28
            }

            return Character(UnicodeScalar(hangulUnicodeOffset + offset)!)
        case (let chosung?, let jungsung?, let jongsung?):
            var offset = 0
            if let chosungOffset = chosungMapOffset[chosung] {
                offset += chosungOffset * jungsungOffset21 * jongsungOffset28
            }
            if let jungsungOffset = jungsungMapOffset[jungsung] {
                offset += jungsungOffset * jongsungOffset28
            }
            if let jongsungOffset = jongsungMapOffset[jongsung] {
                offset += jongsungOffset
            }

            return Character(UnicodeScalar(hangulUnicodeOffset + offset)!)
        default:
            return nil
        }
    }
}
