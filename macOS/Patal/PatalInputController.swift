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

    // 글자 조합, 백스페이스, 엔터, ESC 키 처리
    override func inputText(_ s: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!) -> Bool {
        guard let client = sender as? IMKTextInput else {
            // false 를 반환하는 경우는 시스템에서 string 을 처리하고 출력한다
            return false
        }
        // client 현재 입력기를 사용하는 클라이언트 임. 예를 들면 com.googlecode.iterm2
        let strategy = processor.getInputStrategy(client: client)
        // if let bundleId = client.bundleIdentifier() {
        //    logger.debug("클라이언트: \(bundleId) 전략: \(String(describing: strategy))")
        // }

        if !processor.verifyProcessable(s, keyCode: keyCode, modifierCode: flags) {
            // 엔터 같은 특수 키코드 처리
            let flushed = processor.flushCommit()
            if !flushed.isEmpty {
                logger.debug("내보낼 것: \(flushed)")
                flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }
            }
            return false
        }

        /// 백스페이스 처리 로직
        if keyCode == KeyCode.BACKSPACE.rawValue {
            /// 조합중인 자소가 없으면 처리 중단
            if processor.countComposable() < 1 {
                return false
            }
            /// 조합 중인 자소에 대해 백스페이스 처리 후 조합할 자소가 없다면 마감
            if processor.applyBackspace() < 1 {
                return updateEmptyCommit(client: client)
            }
            /// 조합중이면 클라이언트 특성에 따라 첫/가/끝 역순으로 자소를 제거하면서 setMarkedText 를 수행
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

        /// 한글 조합 시작
        processor.rawChar = s

        /// 비 한글 처리 먼저 진행
        if !processor.verifyCombosable(s) {
            let flushed = processor.flushCommit()
            flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }

            return true
        }

        /// 한글의 핵심 조합이 여기에서 이루어짐
        let nextStatus = processor.한글조합()
        logger.debug("상태: \(String(describing: nextStatus))")

        if let commit = processor.완성 {
            client.insertText(commit, replacementRange: .notFoundRange)
            processor.clearBuffers()
        }

        // updateCommit
        if let commit = processor.composeCommitToUpdate() {
            return updateSelectedRangeCommit(client: client, with: commit)
        }

        return false
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

        let flushed = processor.flushCommit()
        if !flushed.isEmpty {
            logger.debug("강제로 내보낼 것: \(flushed)")
            flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }
        }
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
