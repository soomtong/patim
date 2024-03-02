//
//  InputSource.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Carbon
import Foundation

// sourced by https://github.com/hatashiro/kawa
extension TISInputSource {
    private func getProperty(_ key: CFString) -> AnyObject? {
        let cfType = TISGetInputSourceProperty(self, key)
        if cfType != nil {
            return Unmanaged<AnyObject>.fromOpaque(cfType!).takeUnretainedValue()
        } else {
            return nil
        }
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }
}

// sourced by https://github.com/hatashiro/kawa
class InputSource {
    let tisInputSource: TISInputSource

    init(tisInputSource: TISInputSource) {
        self.tisInputSource = tisInputSource
    }

    static func getCurrentLayout() -> InputSource {
        return InputSource(tisInputSource: TISCopyCurrentKeyboardInputSource().takeRetainedValue())
    }

    static var sources: [InputSource] {
        // 타입(static) 메서드인 `sources` 를 위해 여기에서 CustomLogger 를 생성
        let logger = CustomLogger(category: "InputSourceList")

        let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        let inputSourceList = inputSourceNSArray as! [TISInputSource]

        inputSourceList.forEach {
            logger.debug("\($0.id): \($0.isSelectable)")
        }

        return inputSourceList.filter { $0.isSelectable }.map { InputSource(tisInputSource: $0) }
    }

}
