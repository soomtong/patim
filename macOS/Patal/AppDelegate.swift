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
//        let notificationCenter = UNUserNotificationCenter.current()
        UNUserNotificationCenter.current().delegate = self

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

        let notificatonContent = UNMutableNotificationContent()
        notificatonContent.title = "팥알입력기"
        notificatonContent.body = "디버그 메시지로 활용하도록 함"
        notificatonContent.categoryIdentifier = "alarm"
        notificatonContent.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
 
        let request1 = UNNotificationRequest(identifier: UUID().uuidString, content: notificatonContent, trigger: trigger)
        notificationCenter.add(request1) { (error) in
            if error != nil {
                print(error?.localizedDescription as Any)
            }
        }
        
//        let request2 = UNNotificationRequest(identifier: UUID().uuidString, content: notificatonContent, trigger: trigger)
//        notificationCenter.add(request2)
        
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        return completionHandler([.sound])
    }
}
