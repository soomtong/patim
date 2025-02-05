//
//  HangulComposition.swift
//  Patal
//
//  Created by dp on 12/4/24.
//

import Foundation

/// 초성 19조합: ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ
let chosungMap: [초성] = [
    초성.기역, 초성.쌍기역, 초성.니은, 초성.디귿, 초성.쌍디귿, 초성.리을, 초성.미음, 초성.비읍, 초성.쌍비읍, 초성.시옷,
    초성.쌍시옷, 초성.이응, 초성.지읒, 초성.쌍지읒, 초성.치읓, 초성.키읔, 초성.티긑, 초성.피읖, 초성.히읗,
]
let chosungMapOffset: [초성: Int] = generateOffsetDictionary(chosungMap)

/// 중성 21조합: ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ
let jungsungMap: [중성] = [
    중성.아, 중성.애, 중성.야, 중성.얘, 중성.어, 중성.에, 중성.여, 중성.예, 중성.오, 중성.와,
    중성.왜, 중성.외, 중성.요, 중성.우, 중성.워, 중성.웨, 중성.위, 중성.유, 중성.으, 중성.의, 중성.이,
]
let jungsungMapOffset: [중성: Int] = generateOffsetDictionary(jungsungMap)

/// 종성 28조합: (빈 끝소리) + ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ
let jongsungMap: [종성] = [
    종성.없음, 종성.기역, 종성.쌍기역, 종성.기역시옷, 종성.니은, 종성.니은지읒, 종성.니은히읗, 종성.디귿,
    종성.리을, 종성.리을기역, 종성.리을미음, 종성.리을비읍, 종성.리을시옷, 종성.리을티긑,
    종성.리을피읖, 종성.리을히읗, 종성.미음, 종성.비읍, 종성.비읍시옷, 종성.시옷, 종성.쌍시옷,
    종성.이응, 종성.지읒, 종성.치읓, 종성.키읔, 종성.티긑, 종성.피읖, 종성.히흫,
]
let jongsungMapOffset: [종성: Int] = generateOffsetDictionary(jongsungMap)

let hangulUnicodeOffset = 0xAC00

let chosungOffset19 = chosungMap.count
let jungsungOffset21 = jungsungMap.count
let jongsungOffset28 = jongsungMap.count

let compat초성Map: [초성: 자음] = [
    초성.기역: 자음.기역, 초성.쌍기역: 자음.쌍기역, 초성.니은: 자음.니은, 초성.디귿: 자음.디귿,
    초성.쌍디귿: 자음.쌍디귿, 초성.리을: 자음.리을, 초성.미음: 자음.미음, 초성.비읍: 자음.비읍,
    초성.쌍비읍: 자음.쌍비읍, 초성.시옷: 자음.시옷, 초성.쌍시옷: 자음.쌍시옷, 초성.이응: 자음.이응,
    초성.지읒: 자음.지읒, 초성.쌍지읒: 자음.쌍지읒, 초성.치읓: 자음.치읓, 초성.키읔: 자음.키읔,
    초성.티긑: 자음.티긑, 초성.피읖: 자음.피읖, 초성.히읗: 자음.히읗,
]
let compat중성Map: [중성: 모음] = [
    중성.아: 모음.아, 중성.애: 모음.애, 중성.야: 모음.야, 중성.얘: 모음.얘, 중성.어: 모음.어,
    중성.에: 모음.에, 중성.여: 모음.여, 중성.예: 모음.예, 중성.오: 모음.오, 중성.와: 모음.와,
    중성.왜: 모음.왜, 중성.외: 모음.외, 중성.요: 모음.요, 중성.우: 모음.우, 중성.워: 모음.워,
    중성.웨: 모음.웨, 중성.위: 모음.위, 중성.유: 모음.유, 중성.으: 모음.으, 중성.의: 모음.의,
    중성.이: 모음.이,
]
let compat종성Map: [종성: 자음] = [
    종성.없음: 자음.채움, 종성.기역: 자음.기역, 종성.쌍기역: 자음.쌍기역, 종성.기역시옷: 자음.기역시옷,
    종성.니은: 자음.니은, 종성.니은지읒: 자음.니은지읒, 종성.니은히읗: 자음.니은히읗,
    종성.디귿: 자음.디귿, 종성.리을: 자음.리을, 종성.리을기역: 자음.리을기역,
    종성.리을미음: 자음.리을미음, 종성.리을비읍: 자음.리을비읍, 종성.리을시옷: 자음.리을시옷,
    종성.리을티긑: 자음.리을티긑, 종성.리을피읖: 자음.리을피읖, 종성.리을히읗: 자음.리을히읗,
    종성.미음: 자음.미음, 종성.비읍: 자음.비읍, 종성.비읍시옷: 자음.비읍시옷,
    종성.시옷: 자음.시옷, 종성.쌍시옷: 자음.쌍시옷, 종성.이응: 자음.이응, 종성.지읒: 자음.지읒,
    종성.치읓: 자음.치읓, 종성.키읔: 자음.키읔, 종성.티긑: 자음.티긑, 종성.피읖: 자음.피읖, 종성.히흫: 자음.히읗,
]

/// 한글 낱자를 조합하는 객체
/// 글자를 생성하고 출력할 수 있는 형태로 변환
class HangulComposer {
    private var chosungCode: 초성?
    private var jungsungCode: 중성?
    private var jongsungCode: 종성?

    init?(chosungPoint: 초성?, jungsungPoint: 중성?, jongsungPoint: 종성?) {
        switch (chosungPoint, jungsungPoint, jongsungPoint) {
        // 닿소리 홀소리 하나만
        case (let chosungPoint?, nil, nil)
        where chosungMapOffset[chosungPoint] != nil:
            chosungCode = chosungPoint

        case (nil, let jungsungPoint?, nil)
        where jungsungMapOffset[jungsungPoint] != nil:
            jungsungCode = jungsungPoint

        case (nil, nil, let jongsungPoint?)
        where jongsungMapOffset[jongsungPoint] != nil:
            jongsungCode = jongsungPoint

        // 조합: 초성이 없거나 중성이 없는 조합은 배제한다.
        case (let chosungPoint?, let jungsungPoint?, nil)
        where chosungMapOffset[chosungPoint] != nil && jungsungMapOffset[jungsungPoint] != nil:
            chosungCode = chosungPoint
            jungsungCode = jungsungPoint

        case (let chosungPoint?, let jungsungPoint?, let jongsungPoint?)
        where chosungMapOffset[chosungPoint] != nil && jungsungMapOffset[jungsungPoint] != nil
            && jongsungMapOffset[jongsungPoint] != nil:
            chosungCode = chosungPoint
            jungsungCode = jungsungPoint
            jongsungCode = jongsungPoint

        // 아니 느슨한 조합을 할 수 있지 않을까?
        case (let chosungPoint?, nil, let jongsungPoint?)
        where chosungMapOffset[chosungPoint] != nil && jongsungMapOffset[jongsungPoint] != nil:
            chosungCode = chosungPoint
            jongsungCode = jongsungPoint

        case (nil, let jungsungPoint?, let jongsungPoint?)
        where jungsungMapOffset[jungsungPoint] != nil && jongsungMapOffset[jongsungPoint] != nil:
            jungsungCode = jungsungPoint
            jongsungCode = jongsungPoint

        default:
            return nil
        }
    }

    /// 객체에 저장된 첫/가/끝 낱자를 조합 글자로 반환
    func getSyllable() -> Character? {
        switch (chosungCode, jungsungCode, jongsungCode) {
        case (nil, nil, nil):
            return nil

        // 닿소리와 홀소리: 호환 자모로 변환하여 제공
        case (_?, nil, nil):
            return normalizeCompat(음소.첫소리)
        case (nil, _?, nil):
            return normalizeCompat(음소.가운뎃소리)
        case (nil, nil, _?):
            return normalizeCompat(음소.끝소리)

        // 완성 낱자: 첫/가 조합
        case (let chosungPoint?, let jungsungPoint?, nil):
            var offset = 0
            if let chosungOffset = chosungMapOffset[chosungPoint] {
                offset += chosungOffset * jungsungOffset21 * jongsungOffset28
            }
            if let jungsungOffset = jungsungMapOffset[jungsungPoint] {
                offset += jungsungOffset * jongsungOffset28
            }
            return Character(UnicodeScalar(hangulUnicodeOffset + offset)!)
        // 완성 낱자: 첫/가/끝 조합
        case (let chosungPoint?, let jungsungPoint?, let jongsungPoint?):
            var offset = 0
            if let chosungOffset = chosungMapOffset[chosungPoint] {
                offset += chosungOffset * jungsungOffset21 * jongsungOffset28
            }
            if let jungsungOffset = jungsungMapOffset[jungsungPoint] {
                offset += jungsungOffset * jongsungOffset28
            }
            if let jongsungOffset = jongsungMapOffset[jongsungPoint] {
                offset += jongsungOffset
            }
            return Character(UnicodeScalar(hangulUnicodeOffset + offset)!)

        // 미완성 낱자
        case (_, nil, _):
            print("조합 중...일까? 중성이 와야해...")
            return Character(UnicodeScalar(그외.대체문자.rawValue)!)

        case (nil, _, _):
            print("조합 중...일까? 초성이 와야해...")
            return Character(UnicodeScalar(그외.대체문자.rawValue)!)
        }
    }

    /// 유니코드 첫/가/끝 낱자를 호환성이 높은 코드로 전환
    func normalizeCompat(_ 낱자: 음소) -> Character {
        switch 낱자 {
        case .첫소리:
            let codePoint = compat초성Map[chosungCode!]?.rawValue ?? 그외.대체문자.rawValue
            return Character(UnicodeScalar(codePoint)!)
        case .가운뎃소리:
            let codePoint = compat중성Map[jungsungCode!]?.rawValue ?? 그외.대체문자.rawValue
            return Character(UnicodeScalar(codePoint)!)
        case .끝소리:
            let codePoint = compat종성Map[jongsungCode!]?.rawValue ?? 그외.대체문자.rawValue
            return Character(UnicodeScalar(codePoint)!)
        }
    }
}
