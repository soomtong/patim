//
//  PatalInputController.swift
//  Patal
//
//  Created by dp on 12/29/24.
//

import AppKit
import Foundation
import InputMethodKit

extension InputController {
    // 조합 중인 글자를 커밋
    private func flushComposition(client: IMKTextInput) {
        let flushed = processor.flushCommit()
        if !flushed.isEmpty {
            logger.debug("내보낼 것: \(flushed)")
            flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }
        }
    }

    // 모든 키 이벤트를 handle 에서 처리 (Apple SDK 권장: 이벤트 수신 방식은 하나만 선택)
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard event.type == .keyDown else {
            return false
        }
        guard let client = sender as? IMKTextInput else {
            return false
        }

        let keyCode = Int(event.keyCode)
        let flags = Int(event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue)
        let s = event.characters ?? ""

        // 화살표 키: flush 후 시스템에 넘김 (커서 이동)
        if (123...126).contains(keyCode) {
            if processor.countComposable() > 0 {
                flushComposition(client: client)
                processor.clearBuffers()
            }
            return false
        }

        // ESC: flush 후 조합 중이었으면 소비, 아니면 시스템에 넘김
        // ESC 문자(0x1B)가 삽입되지 않도록 조합 중에는 여기서 소비
        if keyCode == KeyCode.ESC.rawValue {
            if processor.countComposable() > 0 {
                flushComposition(client: client)
                processor.clearBuffers()
                return true
            }
            return false
        }

        // 처리 가능 여부 검증
        let strategy = processor.getInputStrategy(client: client)
        if let bundleId = client.bundleIdentifier() {
            logger.debug("클라이언트: \(bundleId) 전략: \(String(describing: strategy))")
        }

        if !processor.verifyProcessable(s, keyCode: keyCode, modifierCode: flags) {
            flushComposition(client: client)
            return false
        }

        /// 백스페이스 처리 로직
        if keyCode == KeyCode.BACKSPACE.rawValue {
            if processor.countComposable() < 1 {
                return false
            }
            if processor.applyBackspace() < 1 {
                return updateEmptyCommit(client: client)
            }
            if let commit = processor.composeCommitToUpdate() {
                switch strategy {
                case .directInsert:
                    return updateReplacementRangeCommit(client: client, with: commit)
                case .swapMarked:
                    return updateDefaultRangeCommit(client: client, with: commit)
                }
            }
            return false
        }

        /// 한글 조합 시작 - 키코드 기반 처리 (라틴 자판 독립적)
        var baseChar: String = s

        if KeyCodeMapper.isHangulInputKey(keyCode: keyCode) {
            if let keyCodeChar = processor.processKeyCodeInput(keyCode: keyCode, modifiers: flags) {
                baseChar = keyCodeChar
                logger.debug("키코드 기반 입력: \(KeyCodeMapper.debugKeyInfo(keyCode: keyCode, modifiers: flags))")
            }
        } else {
            processor.rawChar = s
        }

        /// 비 한글 처리 먼저 진행
        if !processor.verifyCombosable(baseChar) {
            flushComposition(client: client)
            return true
        }

        /// 한글의 핵심 조합이 여기에서 이루어짐
        let nextStatus = processor.한글조합()
        logger.debug("상태: \(String(describing: nextStatus))")

        if let commit = processor.완성 {
            client.insertText(commit, replacementRange: .notFoundRange)
            processor.clearBuffers()
        }

        if let commit = processor.composeCommitToUpdate() {
            return updateSelectedRangeCommit(client: client, with: commit)
        }

        return false
    }

    // 백스페이스 처리
    private func updateEmptyCommit(client: IMKTextInput) -> Bool {
        client.setMarkedText("", selectionRange: .defaultRange, replacementRange: .defaultRange)
        return true
    }

    private func updateReplacementRangeCommit(client: IMKTextInput, with: String) -> Bool {
        let selectedRange = client.selectedRange()
        let replacementRange = NSRange(
            location: max(0, selectedRange.location - with.count),
            length: min(NSNotFound, selectedRange.length + with.count))

        client.setMarkedText(with, selectionRange: .defaultRange, replacementRange: replacementRange)
        return true
    }

    private func updateDefaultRangeCommit(client: IMKTextInput, with: String) -> Bool {
        let string = NSAttributedString(string: with, attributes: [.backgroundColor: NSColor.clear])
        client.setMarkedText(string, selectionRange: .defaultRange, replacementRange: .defaultRange)
        return true
    }

    // 조합 처리
    private func updateSelectedRangeCommit(client: IMKTextInput, with: String) -> Bool {
        let selection = NSRange(location: 0, length: with.count)
        client.setMarkedText(with, selectionRange: selection, replacementRange: .notFoundRange)
        return true
    }

    // 입력기 메뉴가 열릴 때마다 호출됨
    override open func menu() -> NSMenu! {
        return optionMenu.menu
    }

    // 자판 전환, 마우스 클릭 등으로 조합을 끝낼 경우
    override func commitComposition(_ sender: Any!) {
        logger.debug("자판 전환, 마우스 클릭 등으로 조합을 끝낼 경우")
        guard let client = sender as? IMKTextInput else {
            return
        }

        flushComposition(client: client)
    }

    // 입력기 메뉴의 옵션이 변경되는 경우 호출됨
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
                    in: &processor.hangulLayout)

                logger.debug("특성 저장: \([traitKey: traitValue])")
                keepUserTraits(traitKey: traitKey, traitValue: traitValue)
            }
        }
    }
}
