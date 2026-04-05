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

    // 조합 처리 (InputStrategy 구분 없이 모든 앱에서 공통 호출)
    // plain String을 전달하면 클라이언트가 자체 스타일(선택 하이라이트)을 적용하므로
    // NSAttributedString에 밑줄 속성을 명시하여 macOS 내장 입력기와 동일한 밑줄 표시를 사용한다
    private func updateSelectedRangeCommit(client: IMKTextInput, with: String) -> Bool {
        let attributed = NSAttributedString(string: with, attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .markedClauseSegment: 0,
        ])
        let cursorAtEnd = NSRange(location: with.count, length: 0)
        client.setMarkedText(attributed, selectionRange: cursorAtEnd, replacementRange: .notFoundRange)
        return true
    }

    /// 빠른마침표: 더블스페이스 판정 대기 시간 (초)
    private static let pendingSpaceTimeout: Double = 0.25

    private func startPendingSpaceTimer(client: IMKTextInput) {
        pendingSpaceTimer?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.processor.hasPendingSpace else { return }
            self.processor.flushPendingSpace()
            client.insertText(" ", replacementRange: .notFoundRange)
        }
        pendingSpaceTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.pendingSpaceTimeout, execute: work)
    }

    private func cancelPendingSpaceTimer() {
        pendingSpaceTimer?.cancel()
        pendingSpaceTimer = nil
    }

    // 글자 조합, 백스페이스, 엔터, ESC 키 처리
    override func inputText(_ s: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!) -> Bool {
        guard let client = sender as? IMKTextInput else {
            return false
        }
        let modifiers = UInt(bitPattern: flags)
        // client 현재 입력기를 사용하는 클라이언트 임. 예를 들면 com.googlecode.iterm2
        let strategy = processor.getInputStrategy(client: client)
        if let bundleId = client.bundleIdentifier() {
            logger.debug("클라이언트: \(bundleId) 전략: \(String(describing: strategy))")
        }

        /// 빠른마침표: 보류 중인 스페이스 처리 (모든 키 이벤트에서 먼저 확인)
        if processor.hasPendingSpace {
            cancelPendingSpaceTimer()
            if keyCode == KeyCode.SPACE.rawValue && modifiers == ModifierCode.NONE.rawValue
                && processor.hangulLayout.can빠른마침표
                && processor.consumePendingSpaceAsDouble()
            {
                // 더블스페이스 (500ms 이내): 보류 스페이스를 마침표 + 공백으로 변환
                logger.debug("빠른마침표: 더블스페이스 → 마침표 + 공백")
                client.insertText(". ", replacementRange: .notFoundRange)
                return true
            }
            // 타임아웃 또는 다른 키: 보류 스페이스를 일반 스페이스로 삽입
            processor.flushPendingSpace()
            client.insertText(" ", replacementRange: .notFoundRange)
            // 현재 키 이벤트는 아래에서 정상 처리
        }

        /// 빠른마침표: 한글 flush 후 스페이스를 보류
        if keyCode == KeyCode.SPACE.rawValue && modifiers == ModifierCode.NONE.rawValue
            && processor.hangulLayout.can빠른마침표
        {
            let flushed = processor.flushCommit()
            if !flushed.isEmpty {
                logger.debug("내보낼 것: \(flushed)")
                flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }
                // 한글 flush 후 스페이스: 보류 상태로 전환 (아직 삽입하지 않음)
                processor.setPendingSpace()
                startPendingSpaceTimer(client: client)
                return true
            }
            // 한글 입력 없는 스페이스: OS에게 처리를 넘김
            return false
        }

        /// 옵션라틴: Option 키가 눌린 경우 라틴 문자를 직접 commit
        if processor.hangulLayout.can옵션라틴
            && (modifiers & ModifierCode.ALT.rawValue) != 0
            && KeyCodeMapper.isHangulInputKey(keyCode: keyCode)
        {
            // 조합 중인 한글을 먼저 flush
            let flushed = processor.flushCommit()
            if !flushed.isEmpty {
                logger.debug("옵션라틴 flush: \(flushed)")
                flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }
            }
            // ALT 비트를 제거하고 SHIFT만 남겨서 라틴 문자 획득
            let shiftOnly = modifiers & ModifierCode.SHIFT.rawValue
            if let latinChar = KeyCodeMapper.mapKeyCodeToHangulChar(keyCode: keyCode, modifiers: shiftOnly) {
                logger.debug("옵션라틴 입력: \(latinChar)")
                client.insertText(latinChar, replacementRange: .notFoundRange)
                return true
            }
        }

        if !processor.verifyProcessable(s, keyCode: keyCode, modifierCode: modifiers) {
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
            /// 기호 확장 백스페이스 (layerSelected → triggered 복귀)
            if processor.handleSymbolBackspace() {
                if let commit = processor.composeCommitToUpdate() {
                    return updateSelectedRangeCommit(client: client, with: commit)
                }
                return updateEmptyCommit(client: client)
            }
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
            if let keyCodeChar = processor.processKeyCodeInput(keyCode: keyCode, modifiers: modifiers) {
                baseChar = keyCodeChar
                logger.debug("키코드 기반 입력: \(KeyCodeMapper.debugKeyInfo(keyCode: keyCode, modifiers: modifiers))")
            }
        } else {
            // 키코드 매핑이 없는 경우 기존 문자열 사용 (하위 호환성)
            processor.rawChar = s
        }

        /// 기호 확장 처리 (triggered/layerSelected 상태)
        if processor.symbolState != .inactive {
            if let symbolResult = processor.handleSymbolExtension() {
                if symbolResult.isEmpty {
                    // 단 선택 완료 → preedit 해제
                    return updateEmptyCommit(client: client)
                } else {
                    // 기호 출력
                    client.insertText(symbolResult, replacementRange: .notFoundRange)
                    return true
                }
            }
            // nil = 기호 확장이 처리하지 않음 → 정상 한글 조합 계속
        }

        /// 비 한글 처리 먼저 진행
        if !processor.verifyCombosable(baseChar) {
            let flushed = processor.flushCommit()
            flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }

            return true
        }

        /// 한글의 핵심 조합이 여기에서 이루어짐
        let nextStatus = processor.한글조합WithSymbolCheck()
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
    override func menu() -> NSMenu! {
        return optionMenu.menu
    }

    // 자판 전환, 마우스 클릭 등으로 조합을 끝낼 경우
    override func commitComposition(_ sender: Any!) {
        logger.debug("자판 전환, 마우스 클릭 등으로 조합을 끝낼 경우")
        guard let client = sender as? IMKTextInput else {
            return
        }

        // 기호 확장 상태 리셋
        processor.resetSymbolState()

        // 빠른마침표: 보류 중인 스페이스가 있으면 삽입
        if processor.hasPendingSpace {
            cancelPendingSpaceTimer()
            processor.flushPendingSpace()
            client.insertText(" ", replacementRange: .notFoundRange)
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
