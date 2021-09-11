//
//  AppDelegate.swift
//  Patal
//
//  Created by EarthShaker on 2021/09/11.
//

import Cocoa
import UserNotifications


@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    
    let notificationCenter = UNUserNotificationCenter.current()
        
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        self.registNotificationHandler()
        let notificationContent = NotificatonContent(title: "팥알입력기", body: "디버그 메시지로 활용하도록 함")
        
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
    
    func registNotificationHandler() -> Void {
        self.notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
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

    func pushNotification(from: NotificatonContent) {
        let notificatonContent = UNMutableNotificationContent()
        notificatonContent.title = from.title
        notificatonContent.body = from.body
        notificatonContent.categoryIdentifier = "alarm"
        notificatonContent.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
 
        let request1 = UNNotificationRequest(identifier: UUID().uuidString, content: notificatonContent, trigger: trigger)
        self.notificationCenter.add(request1) { (error) in
            if error != nil {
                print(error?.localizedDescription as Any)
            }
        }
    }
}
