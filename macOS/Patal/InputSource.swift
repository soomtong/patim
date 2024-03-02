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

    static var uSeconds: UInt32 = 20000

    init(tisInputSource: TISInputSource) {
        self.tisInputSource = tisInputSource
    }

    static func getCurrentLayout() -> InputSource {
        return InputSource(tisInputSource: TISCopyCurrentKeyboardInputSource().takeRetainedValue())
    }

    static func postPreviousLayoutKey() {
        // 타입(static) 메서드 안에서 CustomLogger 를 생성
        let logger = CustomLogger(category: "InputSourceShoutcut")

        logger.debug("강제 입력기 전환: 이전 입력기 전환 단축키 전송")

        let shortcut = getSelectPreviousLayoutShortcut()
        if shortcut == nil {
            logger.error("이전 입력기 전환 키가 반드시 등록되어 있어야 함")
            return
        }

        let keyCode = CGKeyCode(shortcut!.0)
        let eventFlags = CGEventFlags(rawValue: shortcut!.1)
        let eventSource = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true)!
        keyDown.flags = eventFlags
        keyDown.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false)!
        // if with flag, a pop up will show up
        // up.flags = flag;
        keyUp.post(tap: .cghidEventTap)

        usleep(self.uSeconds)
    }

    // from read-symbolichotkeys script of Karabiner
    // github.com/tekezo/Karabiner/blob/master/src/util/read-symbolichotkeys/read-symbolichotkeys/main.m
    static func getSelectPreviousLayoutShortcut() -> (Int, UInt64)? {
        let logger = CustomLogger(category: "InputSourceShoutcutGrapper")

        guard let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.symbolichotkeys") else {
            logger.debug("symbolichotkeys 구하기 실패")
            return nil
        }
        logger.debug("symbolichotkeys 구하기: \(dict)")
        guard let symbolicHotkeys = dict["AppleSymbolicHotKeys"] as! NSDictionary? else {
            logger.debug("AppleSymbolicHotKeys 구하기 실패")
            return nil
        }
        logger.debug("AppleSymbolicHotKeys 구하기: \(symbolicHotkeys)")
        guard let symbolicHotkey = symbolicHotkeys["60"] as! NSDictionary? else {
            logger.debug("AppleSymbolicHotKey 구하기 실패")
            return nil
        }

        logger.debug("AppleSymbolicHotKey 구하기: \(symbolicHotkey)")
        if (symbolicHotkey["enabled"] as! NSNumber).intValue != 1 {
            logger.debug("AppleSymbolicHotKey enabled 구하기 실패")
            return nil
        }

        guard let value = symbolicHotkey["value"] as! NSDictionary? else {
            return nil
        }
        logger.debug("value 구하기: \(value)")
        guard let parameters = value["parameters"] as! NSArray? else {
            logger.debug("AppleSymbolicHotKey parameters 구하기 실패")
            return nil
        }
        logger.debug("parameters 구하기: \(parameters)")

        return (
            (parameters[1] as! NSNumber).intValue,
            (parameters[2] as! NSNumber).uint64Value
        )
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

    var isCJKV: Bool {
        if let lang = self.tisInputSource.sourceLanguages.first {
            return lang == "ko" || lang == "ja" || lang == "vi" || lang.hasPrefix("zh")
        }
        return false
    }
}
