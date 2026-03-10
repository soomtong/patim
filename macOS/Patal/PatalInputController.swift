//
//  PatalInputController.swift
//  Patal
//
//  Created by dp on 12/29/24.
//

import AppKit
import Foundation
import IMKSwift

extension InputController {
    // 백스페이스 처리
    private func updateEmptyCommit(client: any IMKTextInput) -> Bool {
        client.setMarkedText("", selectionRange: .defaultRange, replacementRange: .defaultRange)
        return true
    }

    private func updateReplacementRangeCommit(client: any IMKTextInput, with: String) -> Bool {
        let selectedRange = client.selectedRange()
        let replacementRange = NSRange(
            location: max(0, selectedRange.location - with.count),
            length: min(NSNotFound, selectedRange.length + with.count))

        client.setMarkedText(with, selectionRange: .defaultRange, replacementRange: replacementRange)
        return true
    }

    private func updateDefaultRangeCommit(client: any IMKTextInput, with: String) -> Bool {
        let string = NSAttributedString(string: with, attributes: [.backgroundColor: NSColor.clear])
        client.setMarkedText(string, selectionRange: .defaultRange, replacementRange: .defaultRange)
        return true
    }

    // 조합 처리 (InputStrategy 구분 없이 모든 앱에서 공통 호출)
    // plain String을 전달하면 클라이언트가 자체 스타일(선택 하이라이트)을 적용하므로
    // NSAttributedString에 밑줄 속성을 명시하여 macOS 내장 입력기와 동일한 밑줄 표시를 사용한다
    private func updateSelectedRangeCommit(client: any IMKTextInput, with: String) -> Bool {
        let attributed = NSAttributedString(string: with, attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .markedClauseSegment: 0,
        ])
        let cursorAtEnd = NSRange(location: with.count, length: 0)
        client.setMarkedText(attributed, selectionRange: cursorAtEnd, replacementRange: .notFoundRange)
        return true
    }

    // 글자 조합, 백스페이스, 엔터, ESC 키 처리
    override func inputText(_ s: String, key keyCode: Int, modifiers flags: UInt, client sender: any IMKTextInput) -> Bool {
        let client = sender
        // client 현재 입력기를 사용하는 클라이언트 임. 예를 들면 com.googlecode.iterm2
        let strategy = processor.getInputStrategy(client: client)
        if let bundleId = client.bundleIdentifier() {
            logger.debug("클라이언트: \(bundleId) 전략: \(String(describing: strategy))")
        }

        /// 빠른마침표: 스페이스바를 빠르게 2번 누르면 마침표로 변환
        if keyCode == KeyCode.SPACE.rawValue && flags == ModifierCode.NONE.rawValue
            && processor.hangulLayout.can빠른마침표
        {
            let flushed = processor.flushCommit()
            if !flushed.isEmpty {
                logger.debug("내보낼 것: \(flushed)")
                flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }
            }

            if processor.checkDoubleSpace() {
                logger.debug("빠른마침표: 더블스페이스 → 마침표")
                // 이전 스페이스를 지우고 마침표를 삽입
                let selectedRange = client.selectedRange()
                let replaceRange = NSRange(
                    location: max(0, selectedRange.location - 1), length: 1)

                switch strategy {
                case .directInsert:
                    client.insertText(".", replacementRange: replaceRange)
                case .swapMarked:
                    // swapMarked 앱(iTerm2, Ghostty 등)에서는 insertText의
                    // replacementRange가 무시될 수 있음
                    // setMarkedText로 이전 스페이스를 마킹한 후 insertText로 교체
                    client.setMarkedText(
                        "", selectionRange: .defaultRange,
                        replacementRange: replaceRange)
                    client.insertText(".", replacementRange: .notFoundRange)
                }
                return true
            }

            // 단일 스페이스: OS에게 처리를 넘김
            return false
        }

        // 스페이스가 아닌 키 입력 시 스페이스 타이머 초기화
        if keyCode != KeyCode.SPACE.rawValue {
            processor.resetSpaceTimer()
        }

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

        /// 한글 조합 시작 - 키코드 기반 처리 (라틴 자판 독립적)
        var baseChar: String = s

        // 키코드 기반 문자 변환 시도 (기본 동작)
        if KeyCodeMapper.isHangulInputKey(keyCode: keyCode) {
            if let keyCodeChar = processor.processKeyCodeInput(keyCode: keyCode, modifiers: flags) {
                baseChar = keyCodeChar
                logger.debug("키코드 기반 입력: \(KeyCodeMapper.debugKeyInfo(keyCode: keyCode, modifiers: flags))")
            }
        } else {
            // 키코드 매핑이 없는 경우 기존 문자열 사용 (하위 호환성)
            processor.rawChar = s
        }

        /// 비 한글 처리 먼저 진행
        if !processor.verifyCombosable(baseChar) {
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
    override func menu() -> NSMenu? {
        return optionMenu.menu
    }

    // 자판 전환, 마우스 클릭 등으로 조합을 끝낼 경우
    override func commitComposition(_ sender: any IMKTextInput) {
        logger.debug("자판 전환, 마우스 클릭 등으로 조합을 끝낼 경우")
        let client = sender

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
