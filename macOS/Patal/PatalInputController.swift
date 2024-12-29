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
                let traitKey = buildTraitKey(name: layoutName)
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
        let loadedTraits = dump.split(separator: ",")
        if loadedTraits.count < 1 || loadedTraits.isEmpty {
            return []
        }
        var traits: [LayoutTrait] = []
        loadedTraits.forEach { label in
            let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
            if let trait = LayoutTrait(rawValue: trimmed) {
                traits.append(trait)
            }
        }
        return traits
    } else {
        return nil
    }
}
