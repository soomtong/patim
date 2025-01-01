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
    @MainActor
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

        // 백스페이스는 별도 처리해야 함
        // 모디파이어가 있는 경우는 비한글 처리해야 함
        // OS 에게 처리 절차를 바로 넘기는 조건
        // - 백스페이스 + 글자단위 삭제 특성이 활성화 된 경우
        // - command, option 키와 함께 사용되는 경우
        // - 한글 레이아웃 자판 맵에 등록되지 않은 키코드 인 경우
        if !processor.verifyProcessable(rawStr, keyCode: keyCode, modifierCode: flags) {
            // 백스페이스/엔터/그 외 키코드 처리
            let flushed = processor.flushCommit()
            flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }

            /// false 를 반환하는 경우는 시스템에서 rawStr 를 처리하고 출력한다
            return false
        }

        // 백스페이스 처리 로직이 필요함
        // 첫/가/끝 역순으로 자소를 제거하면서 setMarkedText 를 수행
        if keyCode == KeyCode.BACKSPACE.rawValue {
            if !processor.composable() {
                return false
            }
            processor.doBackspace()
            // 한글 조합이 되고 있으면 다시 그리기
            if let commit = processor.composeCommitToUpdate() {
                logger.debug("혹시라도 그릴게 있나? \(String(describing: commit))")
                if strategy == .directInsert {
                    let x = client.selectedRange()
                    let count = commit.utf16.count
                    let prevRange = NSRange(
                        location: max(0, x.location - count),
                        length: min(NSNotFound, x.length + count))
                    client.insertText(commit, replacementRange: prevRange)
                } else {
                    let string = NSAttributedString(string: commit, attributes: [.backgroundColor: NSColor.clear])
                    client.setMarkedText(string, selectionRange: .defaultRange, replacementRange: .defaultRange)
                }

                return true
            }
            // xxx: 여기가 마지막 핵심일지도
            processor.clearBuffers()
            logger
                .debug(
                    "아아~ 백스페이스 \(String(describing: rawStr)), \(String(describing: processor.rawChar)), \(String(describing: processor.previous))"
                )
            //            let flushed = processor.flushCommit()
            //            logger.debug("플러쉬? flushed: \(flushed) \(flushed.count)")
            //            flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }

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
