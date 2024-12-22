//
//  InputController.swift
//  Patal
//
//  Created by TemplarAssassin on 2022/03/13.
//

import Foundation
import InputMethodKit

@objc(PatInputController)
class InputController: IMKInputController {
    let logger = CustomLogger(category: "InputController")

    let processor: HangulProcessor
    var inputMethodLayout = Layout.HAN3_SHIN_PCS

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        if let inputMethodID = getCurrentInputMethodID() {
            inputMethodLayout = getInputLayoutID(id: inputMethodID)
        }
        logger.debug("팥알 입력기 자판: \(inputMethodLayout)")
        self.processor = HangulProcessor(layout: inputMethodLayout)

        super.init(server: server, delegate: delegate, client: inputClient)

        if let inputMethodVersion = getCurrentProjectVersion() {
            logger.debug("팥알 입력기 버전: \(inputMethodVersion)")
        }
    }

    override open func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        logger.debug("입력기 서버 시작")
    }

    override open func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
        logger.debug("입력기 서버 중단")
    }

    // 이 입력 방법은 OS 에서 백스페이스, 엔터 등을 처리함. 즉, 완성된 키코드를 제공함.
    override func inputText(_ rawStr: String!, client sender: Any!) -> Bool {
        guard let client = sender as? IMKTextInput else {
            return false
        }

        // 위치가 여기가 아니어야 함
        if !processor.verifyCombosable(rawStr) {
            logger.debug("처리하지 않는 조합 입력: \(String(describing: rawStr))")
            processor.commit()
            client.insertText(rawStr, replacementRange: .notFound)
            return true
        }

        // client 현재 입력기를 사용하는 클라이언트 임. 예를 들면 com.googlecode.iterm2
        logger.debug("클라이언트: \(client.bundleIdentifier() ?? "")")
        let strategy = processor.getInputStrategy(client: client)
        logger.debug("전략: \(String(describing: strategy))")

        processor.rawChar = rawStr

        let state = processor.composeBuffer()

        // let defaultRange = NSRange(location: NSNotFound, length: 0)
        let replacementRange = NSRange(location: NSNotFound, length: NSNotFound)

        if let commit = processor.완성 {
            client.insertText(commit, replacementRange: replacementRange)
            processor.완성 = nil
        }

        if let hangul = processor.getComposed() {
            let debug = "검수: \(String(describing: hangul))(\(String(describing: state)))"
            logger.debug(debug)

            let selectionRange = NSRange(location: 0, length: hangul.count)
            client
                .setMarkedText(
                    hangul,
                    selectionRange: selectionRange,
                    replacementRange: replacementRange
                )

            //            switch (state, strategy) {
            //            case (ComposeState.committed, InputStrategy.directInsert):
            //                // committed 가 온다면; insertText 하고 flush 해야 함.
            //                client.insertText(hangul, replacementRange: defaultRange)
            //                processor.flush()
            //            case (ComposeState.composing, InputStrategy.directInsert):
            //            // client.insertText(hangul, replacementRange: defaultRange)
            //            case (ComposeState.committed, InputStrategy.swapMarked):
            //                processor.flush()
            //                client.insertText(hangul, replacementRange: defaultRange)
            //            case (ComposeState.composing, InputStrategy.swapMarked):
            //                client
            //                    .setMarkedText(
            //                        hangul,
            //                        selectionRange: defaultRange,
            //                        replacementRange: replacementRange
            //                    )
            //            default:
            //                processor.flush()
            //            }

            return true
        }

        return false
    }

    override func commitComposition(_ sender: Any!) {
        processor.flush()
    }

    //override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //    NSLog("hello patal input method: \(event)")
    //    return false
    //}
}
