//
//  Layout.swift
//  Patal
//
//  Created by dp on 11/9/24.
//

import AppKit
import Foundation

/// 지원하는 레이아웃: InfoPlist 파일 참고
enum LayoutName: String {
    case HAN3_P3 = "InputmethodHan3P3"
    case HAN3_SHIN_P2 = "InputmethodHan3ShinP2"
    case HAN3_SHIN_PCS = "InputmethodHan3ShinPCS"
}

/// 자판 생성 핵심 코드
func createLayoutInstance(name: LayoutName) -> HangulAutomata {
    switch name {
    case .HAN3_P3:
        return Han3P3Layout()
    case .HAN3_SHIN_P2:
        return Han3ShinP2Layout()
    case .HAN3_SHIN_PCS:
        return Han3ShinPcsLayout()
    }
}

enum LayoutTrait: String {
    case 모아주기
    case 아래아
    case 수정기호
    case 두줄숫자
    case 글자단위삭제
}

enum KeyCode: Int {
    case BACKSPACE = 51
    case SPACE = 49
    case ENTER = 76
    case RETURN = 36
    case ESC = 53
}

enum ModifierCode: Int {
    case NONE = 0
    case SHIFT = 131072
    case ALT = 524288
    case CONTROL = 262144
    case COMMAND = 1_048_576
    case COMMAND_SHIFT = 1_179_648
}

let logger = CustomLogger(category: "Layout")

/// 자판의 변경된 옵션을 반영
func toggleLayoutTrait(
    trait: LayoutTrait, for menuItem: NSMenuItem, in layout: inout HangulAutomata
) -> String {

    if layout.traits.contains(trait) {
        layout.traits.remove(at: layout.traits.firstIndex(of: trait)!)
        logger.debug("특성 제거 \(trait.rawValue), \(layout.traits)")
        menuItem.state = NSControl.StateValue.off
    } else {
        layout.traits.insert(trait)
        logger.debug("특성 추가 \(trait.rawValue), \(layout.traits)")
        menuItem.state = NSControl.StateValue.on
    }
    let traiteValue = layout.traits.map({ $0.rawValue }).joined(separator: ",")

    return traiteValue
}

/// 한글 자판 프로토콜
protocol HangulAutomata {
    var availableTraits: Set<LayoutTrait> { get }
    var traits: Set<LayoutTrait> { get set }
    var chosungMap: [String: 초성] { get }
    var jungsungMap: [String: 중성] { get }
    var jongsungMap: [String: 종성] { get }
    var nonSyllableMap: [String: String] { get }
    func pickChosung(by char: String) -> unichar?
    func pickJungsung(by char: String) -> unichar?
    func pickJongsung(by char: String) -> unichar?
    func pickNonSyllable(by char: String) -> String?
}

/// 각 레이아웃이 가져야할 프로토콜의 공용 구현
extension HangulAutomata {
    var can모아주기: Bool {
        return traits.contains(LayoutTrait.모아주기)
    }

    var has수정기호: Bool {
        return traits.contains(LayoutTrait.수정기호)
    }

    var has아래아: Bool {
        return traits.contains(LayoutTrait.아래아)
    }

    var has두줄숫자: Bool {
        return traits.contains(LayoutTrait.두줄숫자)
    }

    var can글자단위삭제: Bool {
        return traits.contains(LayoutTrait.글자단위삭제)
    }

    func pickChosung(by char: String) -> unichar? {
        guard let chosung = chosungMap[char] else {
            return nil
        }

        return chosung.rawValue
    }

    func pickJungsung(by char: String) -> unichar? {
        guard let jungsung = jungsungMap[char] else {
            return nil
        }

        return jungsung.rawValue
    }

    func pickJongsung(by char: String) -> unichar? {
        guard let jongsung = jongsungMap[char] else {
            return nil
        }

        return jongsung.rawValue
    }

    func pickNonSyllable(by char: String) -> String? {
        guard let nonSyllable = nonSyllableMap[char] else {
            return nil
        }

        return nonSyllable
    }
}
