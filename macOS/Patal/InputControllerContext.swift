//
//  InputControllerContext.swift
//  Patal
//

import Foundation
import IMKSwift

final class InputControllerContext {
    weak var controller: InputController?

    let logger = CustomLogger(category: "InputController")
    var layoutName: LayoutName
    var processor: HangulProcessor
    var optionMenu: OptionMenu

    init(controller: InputController, layoutName: LayoutName) {
        self.controller = controller
        self.layoutName = layoutName

        let traitKey = buildTraitKey(name: layoutName)
        let hangulLayout = createLayoutInstance(name: layoutName)
        self.processor = HangulProcessor(layout: hangulLayout)

        if let loadedTraits = loadActiveOptions(traitKey: traitKey) {
            processor.hangulLayout.traits = loadedTraits
        } else {
            processor.hangulLayout.traits = processor.hangulLayout.availableTraits.subtracting([.글자단위삭제])
        }

        self.optionMenu = OptionMenu(layout: processor.hangulLayout)
    }

    func reloadTraits() {
        let traitKey = buildTraitKey(name: layoutName)
        if let loadedTraits = loadActiveOptions(traitKey: traitKey) {
            if processor.hangulLayout.traits != loadedTraits {
                processor.hangulLayout.traits = loadedTraits
                optionMenu = OptionMenu(layout: processor.hangulLayout)
            }
        }
    }

    func updateLayout(to newLayout: LayoutName) {
        let _ = processor.flushCommit()

        layoutName = newLayout
        let hangulLayout = createLayoutInstance(name: layoutName)
        processor = HangulProcessor(layout: hangulLayout)

        let traitKey = buildTraitKey(name: layoutName)
        if let loadedTraits = loadActiveOptions(traitKey: traitKey) {
            processor.hangulLayout.traits = loadedTraits
        } else {
            processor.hangulLayout.traits = processor.hangulLayout.availableTraits.subtracting([.글자단위삭제])
        }

        optionMenu = OptionMenu(layout: processor.hangulLayout)
    }
}
