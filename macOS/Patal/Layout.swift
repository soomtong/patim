//
//  Layout.swift
//  Patal
//
//  Created by dp on 11/9/24.
//

import AppKit
import Foundation

/// 지원하는 레이아웃: InfoPlist 파일 참고
enum Layout: String {
    case HAN3_P2 = "InputmethodHan3P2"
    case HAN3_P3 = "InputmethodHan3P3"
    case HAN3_SHIN_P2 = "InputmethodHan3ShinP2"
    case HAN3_SHIN_PCS = "InputmethodHan3ShinPCS"
}

func bindLayout(layout: Layout) -> HangulAutomata {
    switch layout {
    case .HAN3_P2:
        return Han3P2Layout()
    case .HAN3_P3:
        return Han3P3Layout()
    case .HAN3_SHIN_P2:
        return Han3ShinP2Layout()
    case .HAN3_SHIN_PCS:
        return Han3ShinPcsLayout()
    }
}

enum LayoutTrait: String {
    case 모아치기
    case 아래아
    case 화살표
}

func toggleLayoutTrait(
    trait: LayoutTrait, for menuItem: NSMenuItem, in layout: inout HangulAutomata
) -> String {
    if layout.traits.contains(trait) {
        layout.traits.remove(at: layout.traits.firstIndex(of: trait)!)
        menuItem.state = NSControl.StateValue.off
    } else {
        layout.traits.append(trait)
        menuItem.state = NSControl.StateValue.on
    }
    let traiteValue = layout.traits.map({ $0.rawValue }).joined(
        separator: ",")

    return traiteValue
}

protocol HangulAutomata {
    var availableTraits: [LayoutTrait] { get }
    var traits: [LayoutTrait] { get set }
    var chosungMap: [String: 초성] { get }
    var jungsungMap: [String: 중성] { get }
    var jongsungMap: [String: 종성] { get }
    var nonSyllableMap: [String: String] { get }
    func pickChosung(by char: String) -> unichar?
    func pickJungsung(by char: String) -> unichar?
    func pickJongsung(by char: String) -> unichar?
    func pickNonSyllable(by char: String) -> String?
}

extension HangulAutomata {
    var can모아치기: Bool {
        return self.traits.contains(LayoutTrait.모아치기)
    }

    var has화살표: Bool {
        return self.traits.contains(LayoutTrait.화살표)
    }

    var has아래아: Bool {
        return self.traits.contains(LayoutTrait.아래아)
    }

    func pickChosung(by char: String) -> unichar? {
        guard let chosung = self.chosungMap[char] else {
            return nil
        }

        return chosung.rawValue
    }

    func pickJungsung(by char: String) -> unichar? {
        guard let jungsung = self.jungsungMap[char] else {
            return nil
        }

        return jungsung.rawValue
    }

    func pickJongsung(by char: String) -> unichar? {
        guard let jongsung = self.jongsungMap[char] else {
            return nil
        }

        return jongsung.rawValue
    }

    func pickNonSyllable(by char: String) -> String? {
        guard let nonSyllable = self.nonSyllableMap[char] else {
            return nil
        }

        return nonSyllable
    }
}
