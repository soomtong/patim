//
//  InputSource.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Carbon
import Foundation

// sourced by https://github.com/hatashiro/kawa, https://github.com/laishulu/macism
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

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }

    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }
}

// sourced by https://github.com/hatashiro/kawa, https://github.com/laishulu/macism
class InputSource {
    let tisInputSource: TISInputSource

    init(tisInputSource: TISInputSource) {
        self.tisInputSource = tisInputSource
    }
    
    func select() {
        TISSelectInputSource(self.tisInputSource)
    }
}

extension InputSource {
    static var sources: [InputSource] {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        let inputSourceList = inputSourceNSArray as! [TISInputSource]

        return inputSourceList.filter { $0.isSelectable }.map { InputSource(tisInputSource: $0) }
    }
    
    static func getCurrentLayout() -> InputSource {
        return InputSource(tisInputSource: TISCopyCurrentKeyboardInputSource().takeRetainedValue())
    }
}
