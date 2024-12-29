//
//  InputController.swift
//  Patal
//
//  Created by TemplarAssassin on 2022/03/13.
//

import Foundation
import InputMethodKit

@objc(PatIMKController)
class InputController: IMKInputController {
    let logger = CustomLogger(category: "InputController")

    // 클라이언트 하나 당 하나의 입력기 레이아웃 인스턴스가 사용됨
    let layoutName: LayoutName
    let optionMenu: OptionMenu
    let processor: HangulProcessor

    // 클래스 생성이 하나의 인스턴스에서 이루어지기 때문에 여러개의 Patal 입력기를 동시에 사용할 수 없음.
    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        guard let inputMethodID = getCurrentInputMethodID() else {
            return nil
        }

        layoutName = getInputLayoutID(id: inputMethodID)
        logger.debug("팥알 입력기 자판: \(layoutName)")

        let traitKey = buildTraitKey(name: layoutName)
        let hangulLayout = createLayoutInstance(name: layoutName)
        self.processor = HangulProcessor(layout: hangulLayout)
        logger.debug("팥알 입력기 처리기: \(processor)")

        if let loadedTraits = loadActiveOptions(traitKey: traitKey) {
            self.processor.hangulLayout.traits = loadedTraits
        } else {
            self.processor.hangulLayout.traits = self.processor.hangulLayout.availableTraits
        }
        
        self.optionMenu = OptionMenu(layout: self.processor.hangulLayout)

        super.init(server: server, delegate: delegate, client: inputClient)

        if let inputMethodVersion = getCurrentProjectVersion() {
            logger.debug("팥알 입력기 버전: \(inputMethodVersion)")
        }
    }

    @MainActor
    override open func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        logger.debug("입력기 서버 시작: \(layoutName)")
    }

    @MainActor
    override open func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
        logger.debug("입력기 서버 중단: \(layoutName)")
    }

    override open func menu() -> NSMenu! {
        return self.optionMenu.menu
    }

    // 이 입력 방법은 OS 에서 백스페이스, 엔터 등을 처리함. 즉, 완성된 키코드를 제공함.
    @MainActor
    override func inputText(_ rawStr: String!, client sender: Any!) -> Bool {
        guard let client = sender as? IMKTextInput else {
            return false
        }

        // client 현재 입력기를 사용하는 클라이언트 임. 예를 들면 com.googlecode.iterm2
        // let strategy = processor.getInputStrategy(client: client)
        // if let bundleId = client.bundleIdentifier() {
        //     logger.debug("클라이언트: \(bundleId) 전략: \(String(describing: strategy))")
        // }

        if !processor.verifyProcessable(rawStr) {
            let debug = "처리 불가: \(String(describing: rawStr))"
            logger.debug(debug)

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

        if processor.previous.count > 0 {
            let selection = NSRange(location: 0, length: 0)
            client.setMarkedText(그외.채움문자, selectionRange: selection, replacementRange: .notFound)

            return true
        }

        return false
    }

    override func commitComposition(_ sender: Any!) {
        processor.flushCommit()
    }

    //override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //    NSLog("hello patal input method: \(event)")
    //    return false
    //}
}
