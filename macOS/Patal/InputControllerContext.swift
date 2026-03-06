//
//  InputControllerContext.swift
//  Patal
//

import Foundation
import IMKSwift

final class InputControllerContext {
    nonisolated(unsafe) private static let cache = NSMapTable<NSObject, InputControllerContext>.weakToStrongObjects()

    static func context(for client: any IMKTextInput, controller: InputController) -> InputControllerContext {
        let clientObj = client as! NSObject
        if let cached = cache.object(forKey: clientObj) {
            cached.reassign(controller: controller)
            return cached
        }
        let inputMethodID = getCurrentInputMethodID() ?? "InputmethodHan3P3"
        let layoutName = getInputLayoutID(id: inputMethodID)
        let newContext = InputControllerContext(controller: controller, layoutName: layoutName)
        cache.setObject(newContext, forKey: clientObj)
        return newContext
    }

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
            processor.hangulLayout.traits = processor.hangulLayout.availableTraits
        }

        self.optionMenu = OptionMenu(layout: processor.hangulLayout)
    }

    func reassign(controller: InputController) {
        self.controller = controller
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
            processor.hangulLayout.traits = processor.hangulLayout.availableTraits
        }

        optionMenu = OptionMenu(layout: processor.hangulLayout)
    }
}
