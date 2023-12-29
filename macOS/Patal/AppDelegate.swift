//
//  AppDelegate.swift
//  Patal
//
//  Created by EarthShaker on 2021/09/11.
//

import Cocoa
import UserNotifications
import InputMethodKit

private var server: IMKServer?

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var menu: NSMenu!
    
    let notificationCenter = UNUserNotificationCenter.current()
        
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // load input method server
        let bundle = Bundle.main
        server = IMKServer(name: bundle.infoDictionary?["InputMethodConnectionName"] as? String,
                           bundleIdentifier: bundle.bundleIdentifier)
        
        NSLog("patime launch")
        
        // load notification handler
        UNUserNotificationCenter.current().delegate = self

        registerNotificationHandler()
        let notificationContent = NotificationContent(title: "팥알입력기", body: "디버그 메시지로 활용하도록 함")
        
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                self.pushNotification(from: notificationContent)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("exit application")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        return completionHandler([.sound])
    }
    
    func registerNotificationHandler() -> Void {
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
 
        let request1 = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
        notificationCenter.add(request1) { (error) in
            if error != nil {
                print(error?.localizedDescription as Any)
            }
        }
    }
}
