//
//  AppDelegate.swift
//  Patal
//
//  Created by EarthShaker on 2021/09/11.
//

import Cocoa
import InputMethodKit

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

        logger.debug("팥알 입력기 서비스 등록: \(String(describing: bundle.bundleIdentifier))")
        // 이 값은 System Settings 의 Keyboard > Text Input 에서 제공 받음
        if let inputMethodID = getCurrentInputMethodID() {
            logger.debug("자판 정보: \(inputMethodID)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        logger.debug("팥알 입력기 비활성화")
    }
}
