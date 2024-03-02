//
//  AppDelegate.swift
//  Patal
//
//  Created by EarthShaker on 2021/09/11.
//

import Cocoa
import InputMethodKit
import UserNotifications

private var server: IMKServer?

@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var menu: NSMenu!

    let notificationCenter = UNUserNotificationCenter.current()
    let logger = CustomLogger(category: "AppDelegate")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // load input method server
        let bundle = Bundle.main
        server = IMKServer(
            name: bundle.infoDictionary?["InputMethodConnectionName"] as? String,
            bundleIdentifier: bundle.bundleIdentifier)

        logger.debug("팥알 입력기 활성화")

        // load notification handler
        UNUserNotificationCenter.current().delegate = self

        registerNotificationHandler()

        let bundleVersion = bundle.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let message = "빌드 넘버: \(bundleVersion)"
        let notificationContent = NotificationContent(title: "팥알입력기", body: message)

        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                self.pushNotification(from: notificationContent)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        logger.debug("팥알 입력기 비활성화")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        return completionHandler([.sound])
    }

    func registerNotificationHandler() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            print("requested notification")

            if granted {
                print("notification granted")
            } else if !granted {
                print("notification refused")
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }

    func pushNotification(from: NotificationContent) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = from.title
        notificationContent.body = from.body
        notificationContent.categoryIdentifier = "alarm"
        notificationContent.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request1 = UNNotificationRequest(
            identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
        notificationCenter.add(request1) { (error) in
            if error != nil {
                print(error?.localizedDescription as Any)
            }
        }
    }
}
