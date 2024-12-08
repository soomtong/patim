//
//  HangulComposition.swift
//  Patal
//
//  Created by dp on 12/4/24.
//

import Foundation

// 초성 19개 ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ
//let chosungMap: [초성] = [초성.기역, 초성.쌍기역, 초성.니은, 초성.디귿, 초성.리을,
//    초성.미음, 초성.비읍, 초성.쌍비읍, 초성.시옷, 초성.쌍시옷, 초성.이응, 초성.지읒,
//    초성.쌍지읒, 초성.치읓, 초성.키읔, 초성.티긑, 초성.피읖, 초성.히읗]
let chosungMap: [Character] = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
let chosungMapOffset: [Character: Int] = generateOffsetDictionary(chosungMap)
//let chosungMapOffset2: [Character: Int] = [
//    "ㄱ": 0, "ㄲ": 1, "ㄴ": 2, "ㄷ": 3, "ㄸ": 4, "ㄹ": 5, "ㅁ": 6,
//    "ㅂ": 7, "ㅃ": 8, "ㅅ": 9, "ㅆ": 10, "ㅇ": 11, "ㅈ": 12, "ㅉ": 13,
//    "ㅊ": 14, "ㅋ": 15, "ㅌ": 16, "ㅍ": 17, "ㅎ": 18,
//    chosungMap[0]: 0, chosungMap[1]: 1, chosungMap[2]: 2, chosungMap[3]: 3,
//    chosungMap[4]: 4, chosungMap[5]: 5, chosungMap[6]: 6, chosungMap[7]: 7,
//    chosungMap[8]: 8, chosungMap[9]: 9, chosungMap[10]: 10, chosungMap[11]: 11,
//    chosungMap[12]: 12, chosungMap[13]: 13, chosungMap[14]: 14, chosungMap[15]: 15,
//    chosungMap[16]: 16, chosungMap[17]: 17, chosungMap[18]: 18,
//]

// 중성 21개 ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ
let jungsungMap: [Character] = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")
let jungsungMapOffset: [Character: Int] = generateOffsetDictionary(jungsungMap)
//let jungsungMapOffset2: [Character: Int] = [
//    "ㅏ": 0, "ㅐ": 1, "ㅑ": 2, "ㅒ": 3, "ㅓ": 4, "ㅔ": 5, "ㅕ": 6, "ㅖ": 7,
//    "ㅗ": 8, "ㅘ": 9, "ㅙ": 10, "ㅚ": 11, "ㅛ": 12, "ㅜ": 13, "ㅝ": 14,
//    "ㅞ": 15, "ㅟ": 16, "ㅠ": 17, "ㅡ": 18, "ㅢ": 19, "ㅣ": 20,
//]

// 종성 28개 (빈 끝소리) + ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ
let jongsungMap: [Character] = Array(" ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ")
let jongsungPlusEmptyMapOffset: [Character: Int] = generateOffsetDictionary(jongsungMap)
//let jongsungPlusEmptyMapOffset2: [Character: Int] = [
//    " ": 0, "ㄱ": 1, "ㄲ": 2, "ㄳ": 3, "ㄴ": 4, "ㄵ": 5, "ㄶ": 6, "ㄷ": 7,
//    "ㄹ": 8, "ㄺ": 9, "ㄻ": 10, "ㄼ": 11, "ㄽ": 12, "ㄾ": 13, "ㄿ": 14,
//    "ㅀ": 15, "ㅁ": 16, "ㅂ": 17, "ㅄ": 18, "ㅅ": 19, "ㅆ": 20, "ㅇ": 21,
//    "ㅈ": 22, "ㅊ": 23, "ㅋ": 24, "ㅌ": 25, "ㅍ": 26, "ㅎ": 27,
//]

let hangulUnicodeOffset = 0xAC00

let chosungOffset19 = chosungMap.count
let jungsungOffset21 = jungsungMap.count
let jongsungOffset28 = jongsungMap.count

struct HangulComposition {
    var chosungPoint: Character? = nil
    var jungsungPoint: Character? = nil
    var jongsungPoint: Character? = nil

    init?(chosungPoint: Character?, jungsungPoint: Character?, jongsungPoint: Character?) {
        print(
            "test Syllable compose: \(String(describing: chosungPoint)), \(String(describing: jungsungPoint)), \(String(describing: jongsungPoint))"
        )

        // 초성이 없거나 중성이 없는 조합은 배제한다.
        switch (chosungPoint, jungsungPoint, jongsungPoint) {
        case (let chosungPoint?, nil, nil) where chosungMapOffset[chosungPoint] != nil:
            self.chosungPoint = chosungPoint
        case (nil, let jungsungPoint?, nil) where jungsungMapOffset[jungsungPoint] != nil:
            self.jungsungPoint = jungsungPoint
        case (nil, nil, let jongsungPoint?) where jongsungPlusEmptyMapOffset[jongsungPoint] != nil:
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
            && jongsungPlusEmptyMapOffset[jongsungPoint] != nil:
            self.chosungPoint = chosungPoint
            self.jungsungPoint = jungsungPoint
            self.jongsungPoint = jongsungPoint
        default:
            return nil
        }
    }

    init?(_ character: Character) {
        // print("test Syllable decompose: \(character)")
        switch character {
        case chosungMap[0]...chosungMap[18] where chosungMapOffset[character] != nil:
            chosungPoint = character
        case jungsungMap[0]...jungsungMap[20] where jungsungMapOffset[character] != nil:
            jungsungPoint = character
        case jongsungMap[1]...jongsungMap[27] where jongsungPlusEmptyMapOffset[character] != nil:
            jongsungPoint = character
        case "가"..."힣":
            let baseIndex = Int(character.unicodeScalars.first!.value) - Int(hangulUnicodeOffset)
            // print("베이스 \(baseIndex): char \(character.unicodeScalars.first!.value)")
            let jongsungIndex = baseIndex % jongsungOffset28
            let jungsungIndex = ((baseIndex - jongsungIndex) / jongsungOffset28) % jungsungOffset21
            let chosungIndex =
                (baseIndex - jongsungIndex - (jungsungIndex * jongsungOffset28))
                / (jongsungOffset28 * jungsungOffset21)
            // let chosungIndex = (baseIndex / (jongsungOffset28 * jungsungOffset21))
            // let jungsungIndex = (baseIndex % (jongsungOffset28 * jungsungOffset21)) / jongsungOffset28
            // let jongsungIndex = baseIndex % jongsungOffset28
            print("초성 \(chosungIndex)")
            print("중성 \(jungsungIndex)")
            print("종성 \(jongsungIndex)")

            chosungPoint = chosungMap[chosungIndex]
            jungsungPoint = jungsungMap[jungsungIndex]
            jongsungPoint = jongsungIndex == 0 ? nil : jongsungMap[jongsungIndex]
        default:
            return nil
        }
    }

    func getSyllable() -> Character? {
        switch (chosungPoint, jungsungPoint, jongsungPoint) {
        case (nil, nil, nil):
            return nil
        case (let chosung?, nil, nil):
            return chosung
        case (nil, let jungsug?, nil):
            return jungsug
        case (nil, nil, let jongsung?):
            return jongsung
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
            if let jongsungOffset = jongsungPlusEmptyMapOffset[jongsung] {
                offset += jongsungOffset
            }

            return Character(UnicodeScalar(hangulUnicodeOffset + offset)!)
        default:
            return nil
        }
    }
}
