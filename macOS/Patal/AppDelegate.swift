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
    
    let center = UNUserNotificationCenter.current()

    func applicationDidFinishLaunching(_ aNotification: Notification) {

//        center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted: Bool, error: Error?) -> Void in })
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            print("requested notification")
            
            if granted {
                print("notification granted")
            } else {
                print("notification refused")
            }
        }

        let content = UNMutableNotificationContent()
        content.title = "팥알입력기"
        content.body = "디버그 메시지로 활용하도록 함"
        content.categoryIdentifier = "alarm"
        content.sound = UNNotificationSound.default
        
//        let trigger = UNNotificationTrigger(false)
 
        let request1 = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request1)
        
        let request2 = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request2)
        
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

