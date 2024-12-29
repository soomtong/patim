//
//  PatalInputController.swift
//  Patal
//
//  Created by dp on 12/29/24.
//

import AppKit
import Foundation

extension InputController {
    @objc
    func changeLayoutOption(_ sender: Any?) {
        guard let optionItem = sender as? [String: Any] else {
            return
        }
        //for (key, value) in optionItem { print([key: value]) }
        if let traitMenuItem = optionItem["IMKCommandMenuItem"] as? NSMenuItem {
            if let trait = LayoutTrait(rawValue: traitMenuItem.title) {
                let traitKey = buildTraitKey(layout: inputMethodLayout)
                let traitValue = toggleLayoutTrait(
                    trait: trait, for: traitMenuItem,
                    in: &self.processor.hangulLayout)

                keepUserTraits(traitKey: traitKey, traitValue: traitValue)
            }
        }
    }

}

func loadActiveOptions(traitKey: String) -> [LayoutTrait]? {
    if let dump = retrieveUserTraits(traitKey: traitKey) {
        logger.debug("저장된 특성 옵션: \(dump)")
        let loadedTraits = dump.split(separator: ",")
        if loadedTraits.count < 1 || loadedTraits.isEmpty {
            return []
        }
        var traits: [LayoutTrait] = []
        loadedTraits.forEach { label in
            if let trait = LayoutTrait(
                rawValue: label.trimmingCharacters(in: .whitespacesAndNewlines))
            {
                traits.append(trait)
            }
        }
        return traits
    } else {
        return nil
    }
}
