//
//  AppDelegate.swift
//  Patal
//
//  Created by EarthShaker on 2021/09/11.
//

import Carbon
import Cocoa
import InputMethodKit

extension Notification.Name {
    static let inputSourceChanged = Notification.Name("InputSourceChanged")
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var menu: NSMenu!

    var server: IMKServer?

    internal let logger = CustomLogger(category: "AppDelegate")

    // 입력기가 최초 등록된 경우 호출됨
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // load input method server
        let bundle = Bundle.main
        server = IMKServer(
            name: bundle.infoDictionary?["InputMethodConnectionName"] as? String,
            bundleIdentifier: bundle.bundleIdentifier)

        logger.info("팥알 입력기 서비스 등록: \(String(describing: bundle.bundleIdentifier))")
        // 이 값은 System Settings 의 Keyboard > Text Input 에서 제공 받음
        if let inputMethodID = getCurrentInputMethodID() {
            logger.info("자판 정보: \(inputMethodID)")
        }

        // TIS 입력 소스 변경 알림 구독
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleInputSourceChanged),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
        logger.debug("TIS 입력 소스 변경 알림 구독 완료")
    }

    @objc private func handleInputSourceChanged(_ notification: Notification) {
        PerformanceTracerCompat.measure("AppDelegate.handleInputSourceChanged") {
            logger.debug("TIS 입력 소스 변경 감지")
            NotificationCenter.default.post(name: .inputSourceChanged, object: nil)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
        logger.info("팥알 입력기 비활성화")
    }
}
