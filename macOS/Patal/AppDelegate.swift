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

        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            print("requested notification")
            
            if granted {
                print("notification granted")
            } else {
                print("notification refused")
            }
        }

        let notificatonContent = UNMutableNotificationContent()
        notificatonContent.title = "팥알입력기"
        notificatonContent.body = "디버그 메시지로 활용하도록 함"
        notificatonContent.categoryIdentifier = "alarm"
        notificatonContent.sound = UNNotificationSound.default
        
//        let trigger = UNNotificationTrigger(false)
 
        let request1 = UNNotificationRequest(identifier: UUID().uuidString, content: notificatonContent, trigger: nil)
        notificationCenter.add(request1)
        
        let request2 = UNNotificationRequest(identifier: UUID().uuidString, content: notificatonContent, trigger: nil)
        notificationCenter.add(request2)
        
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

