//
//  SyllableRule.swift
//  Patal
//
//  음절 조합 규칙 프로토콜
//

import Foundation

/// 음절 조합 규칙 프로토콜
/// 자판 레이아웃별로 다른 규칙 적용 가능
protocol SyllableRule {
    /// 해당 초성이 종성으로 사용 가능한지
    func canBeFinal(_ chosung: 초성) -> Bool

    /// 해당 종성을 분리할 수 있는지 (겹받침 → 받침 + 초성)
    /// 예: ㄳ → ㄱ + ㅅ
    func canSplitFinal(_ jongsung: 종성) -> (first: 종성, second: 초성)?

    /// 초성에서 종성으로 변환
    func chosungToJongsung(_ chosung: 초성) -> 종성?

    /// 종성에서 초성으로 변환
    func jongsungToChosung(_ jongsung: 종성) -> 초성?
}

/// 현대 한글 기본 규칙
struct DefaultSyllableRule: SyllableRule {

    // MARK: - 초성 ↔ 종성 변환 테이블

    private let chosungToJongsungMap: [초성: 종성] = [
        .기역: .기역,
        .쌍기역: .쌍기역,
        .니은: .니은,
        .디귿: .디귿,
        .리을: .리을,
        .미음: .미음,
        .비읍: .비읍,
        .시옷: .시옷,
        .쌍시옷: .쌍시옷,
        .이응: .이응,
        .지읒: .지읒,
        .치읓: .치읓,
        .키읔: .키읔,
        .티긑: .티긑,
        .피읖: .피읖,
        .히읗: .히흫,
    ]

    private let jongsungToChosungMap: [종성: 초성] = [
        .기역: .기역,
        .쌍기역: .쌍기역,
        .니은: .니은,
        .디귿: .디귿,
        .리을: .리을,
        .미음: .미음,
        .비읍: .비읍,
        .시옷: .시옷,
        .쌍시옷: .쌍시옷,
        .이응: .이응,
        .지읒: .지읒,
        .치읓: .치읓,
        .키읔: .키읔,
        .티긑: .티긑,
        .피읖: .피읖,
        .히흫: .히읗,
    ]

    // MARK: - 겹받침 분리 테이블

    private let splitTable: [종성: (first: 종성, second: 초성)] = [
        .기역시옷: (.기역, .시옷),
        .니은지읒: (.니은, .지읒),
        .니은히읗: (.니은, .히읗),
        .리을기역: (.리을, .기역),
        .리을미음: (.리을, .미음),
        .리을비읍: (.리을, .비읍),
        .리을시옷: (.리을, .시옷),
        .리을티긑: (.리을, .티긑),
        .리을피읖: (.리을, .피읖),
        .리을히읗: (.리을, .히읗),
        .비읍시옷: (.비읍, .시옷),
    ]

    // MARK: - SyllableRule 구현

    func canBeFinal(_ chosung: 초성) -> Bool {
        chosungToJongsungMap[chosung] != nil
    }

    func canSplitFinal(_ jongsung: 종성) -> (first: 종성, second: 초성)? {
        splitTable[jongsung]
    }

    func chosungToJongsung(_ chosung: 초성) -> 종성? {
        chosungToJongsungMap[chosung]
    }

    func jongsungToChosung(_ jongsung: 종성) -> 초성? {
        jongsungToChosungMap[jongsung]
    }
}
