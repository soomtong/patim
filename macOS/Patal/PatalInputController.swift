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
        // let strategy = processor.getInputStrategy(client: client)
        // if let bundleId = client.bundleIdentifier() {
        //     logger.debug("클라이언트: \(bundleId) 전략: \(String(describing: strategy))")
        // }

        if !processor.verifyProcessable(rawStr) {
            let debug = "비한글 처리 키코드: \(String(describing: keyCode)) (\(String(describing: rawStr)))"
            logger.debug(debug)

            // 백스페이스/엔터/그 외 키코드 처리
            // - 백스페이스: 키코드: 51 (Optional("\134u{08}"))
            // - 스페이스: 키코드: 49 (Optional(" "))
            // - 엔터: 키코드: 36 (Optional("\134r"))
            // - ESC: 키코드: 53 (Optional("\134u{1B}"))

            // 백스페이스 처리 로직이 필요함
            // 첫/가/끝 역순으로 자소를 제거하면서 setMarkedText 를 수행

            // 남은 문자가 있는 경우 내보내자
            if let commit = processor.완성 {
                logger.debug("남은 완성 글자: \(String(describing: commit))")
                client.insertText(commit, replacementRange: .notFound)
            }
            if let preedit = processor.getComposed() {
                // todo: preedit 은 완성된 문자가 아니라 화면에 출력 가능한 형태로 보정해야 함
                // let compat = processor.getCompat(preedit)
                logger.debug("조합 중인 글자: \(String(describing: preedit))")
                client.insertText(preedit, replacementRange: .notFound)
            }

            processor.flushCommit()

            /// false 를 반환하는 경우는 시스템에서 rawStr 를 처리하고 출력한다
            return false
        }

        /// 한글 조합 시작
        processor.rawChar = rawStr

        /// 비 한글 처리 먼저 진행
        if !processor.verifyCombosable(rawStr) {
            if let preedit = processor.getComposed() {
                client.insertText(preedit, replacementRange: .notFound)
            }
            if let nonSyllable = processor.getConverted() {
                client.insertText(nonSyllable, replacementRange: .notFound)
            }

            processor.flushCommit()

            return true
        }

        /// 한글의 핵심 조합이 여기에서 이루어짐
        let nextStatus = processor.한글조합()
        logger.debug("상태: \(String(describing: nextStatus))")

        if let commit = processor.완성 {
            client.insertText(commit, replacementRange: .notFound)
            processor.완성 = nil
        }

        if let hangul = processor.getComposed() {
            let debug = "검수: \(String(describing: hangul))(\(String(describing: nextStatus)))"
            logger.debug(debug)

            /// setMarkedText 로 교체할 영역
            let selection = NSRange(location: 0, length: hangul.count)
            client.setMarkedText(hangul, selectionRange: selection, replacementRange: .notFound)

            return true
        }

        /// 조합이 불가능한 경우 대체 문자를 제공
        if processor.previous.count > 0 {
            let selection = NSRange(location: 0, length: 0)
            client.setMarkedText(그외.대체문자, selectionRange: selection, replacementRange: .notFound)

            return true
        }

        return false
    }

    // 입력기 메뉴가 열릴 때마다 호출됨
    override open func menu() -> NSMenu! {
        return optionMenu.menu
    }

    // 자판 전환/ 마우스 클릭 등으로 조합을 끝낼 경우
    override func commitComposition(_ sender: Any!) {
        logger.debug("자판 전환/ 마우스 클릭 등으로 조합을 끝낼 경우")
        guard let client = sender as? IMKTextInput else {
            return
        }

        // 남은 문자가 있는 경우 내보내자
        if let commit = processor.완성 {
            logger.debug("남은 완성 글자: \(String(describing: commit))")
            client.insertText(commit, replacementRange: .notFound)
        }
        if let preedit = processor.getComposed() {
            // todo: preedit 은 완성된 문자가 아니라 화면에 출력 가능한 형태로 보정해야 함
            // let compat = processor.getCompat(preedit)
            logger.debug("조합 중인 글자: \(String(describing: preedit))")
            client.insertText(preedit, replacementRange: .notFound)
        }
        processor.flushCommit()
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
