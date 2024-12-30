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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // load input method server
        let bundle = Bundle.main
        server = IMKServer(
            name: bundle.infoDictionary?["InputMethodConnectionName"] as? String,
            bundleIdentifier: bundle.bundleIdentifier)

        logger.debug("팥알 입력기 서비스 등록: \(String(describing: bundle.bundleIdentifier))")
        if let inputMethodID = getCurrentInputMethodID() {
            logger.debug("자판 정보: \(inputMethodID)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        logger.debug("팥알 입력기 비활성화")
    }
}
