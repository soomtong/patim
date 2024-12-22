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

        // client 현재 입력기를 사용하는 클라이언트 임. 예를 들면 com.googlecode.iterm2
        let strategy = processor.getInputStrategy(client: client)
        if let bundleId = client.bundleIdentifier() {
            logger.debug("클라이언트: \(bundleId) 전략: \(String(describing: strategy))")
        }

        if !processor.verifyCombosable(rawStr) {
            let debug =
                "처리하지 않는 문자: \(String(describing: rawStr)) - \(String(describing: processor.완성)) - \(String(describing: processor.getComposed()))"
            logger.debug(debug)

            // 남은 문자가 있는 경우 내보내자
            if let commit = processor.완성 {
                client.insertText(commit, replacementRange: .notFound)
            }
            if let preedit = processor.getComposed() {
                // todo: preedit 은 완성된 문자가 아니라 화면에 출력 가능한 형태로 보정해야 함
                let compat = processor.getCompat()
                client.insertText(compat, replacementRange: .notFound)
            }
            processor.flushCommit()

            /// false 를 반환하는 경우는 시스템에서 rawStr 를 처리하고 출력한다
            return false
        }

        processor.rawChar = rawStr

        /// 핵심 조합이 여기에서 이루어짐
        let nextStatus = processor.composeBuffer()

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
        processor.flushCommit()
    }

    //override func handle(_ event: NSEvent, client sender: Any) -> Bool {
    //    NSLog("hello patal input method: \(event)")
    //    return false
    //}
}
