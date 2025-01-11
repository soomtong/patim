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
    // 백스페이스, 엔터, ESC 키등의 추가 처리를 위해 inputText 대상을 변경
    override func inputText(
        _ rawStr: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!
    ) -> Bool {
        guard let client = sender as? IMKTextInput else {
            return false
        }
        // client 현재 입력기를 사용하는 클라이언트 임. 예를 들면 com.googlecode.iterm2
        let strategy = processor.getInputStrategy(client: client)
        if let bundleId = client.bundleIdentifier() {
            logger.debug("클라이언트: \(bundleId) 전략: \(String(describing: strategy))")
        }

        if !processor.verifyProcessable(rawStr, keyCode: keyCode, modifierCode: flags) {
            // 백스페이스/엔터/그 외 키코드 처리
            let flushed = processor.flushCommit()
            flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }

            /// false 를 반환하는 경우는 시스템에서 rawStr 를 처리하고 출력한다
            return false
        }

        /// 백스페이스 처리 로직
        /// client 와 processor 가 자주 사용되어 InputController 내부에 둠
        if keyCode == KeyCode.BACKSPACE.rawValue {
            // 첫/가/끝 역순으로 자소를 제거하면서 setMarkedText 를 수행
            var composableCount = processor.countComposable()
            logger.debug("백스페이스 시작 - 자소 카운트? \(composableCount)")
            if composableCount < 1 {
                return false
            }
            composableCount = processor.applyBackspace()
            // 조합중인 자소가 없으면 처리 중단
            if composableCount < 1 {
                // 하나 남은 자소를 마감 처리
                client.setMarkedText("", selectionRange: .defaultRange, replacementRange: .defaultRange)

                return true
            }
            // 조합중이면 클라이언트 특성에 따라 갱신
            if let commit = processor.composeCommitToUpdate() {
                // Sok 입력기 참고
                let selectedRange = client.selectedRange()
                let replacementRange = NSRange(
                    location: max(0, selectedRange.location - commit.count),
                    length: min(NSNotFound, selectedRange.length + commit.count))

                logger.debug("백스페이스 처리 - 글자 카운트 \(commit.count), 자소 카운트? \(composableCount)")

                switch strategy {
                case .directInsert:
                    if composableCount > 0 {
                        client.setMarkedText(commit, selectionRange: .defaultRange, replacementRange: replacementRange)
                    } else {
                        client.insertText(commit, replacementRange: replacementRange)
                    }
                case .swapMarked:
                    let string = NSAttributedString(string: commit, attributes: [.backgroundColor: NSColor.clear])

                    if composableCount > 0 {
                        client.setMarkedText(string, selectionRange: .defaultRange, replacementRange: .defaultRange)
                    } else {
                        client.insertText(string, replacementRange: replacementRange)
                    }
                }

                return true
            }

            processor.clearBuffers()

            return false
        }

        /// 한글 조합 시작
        processor.rawChar = rawStr

        /// 비 한글 처리 먼저 진행
        if !processor.verifyCombosable(rawStr) {
            let flushed = processor.flushCommit()
            flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }

            return true
        }

        /// 한글의 핵심 조합이 여기에서 이루어짐
        let nextStatus = processor.한글조합()
        logger.debug("상태: \(String(describing: nextStatus))")

        if let commit = processor.완성 {
            client.insertText(commit, replacementRange: .notFoundRange)
            processor.완성 = nil
        }

        // updateCommit
        if let commit = processor.composeCommitToUpdate() {
            let selection = NSRange(location: 0, length: commit.count)
            client.setMarkedText(commit, selectionRange: selection, replacementRange: .notFoundRange)

            return true
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
        flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }
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
