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

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let center = UNUserNotificationCenter.current()
        
//        center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted: Bool, error: Error?) -> Void in
//            if granted {
//                print("Yes")
//            } else {
//                print("No")
//            }
//        })
        
//        center.requestAuthorization(options: [.alert, .badge], completionHandler: {
//            (granted: Bool, error: Error?) -> Void in
//                if granted {
//                    //
//                } else {
//                    //
//                }
//            })
        
        center.requestAuthorization(options: [.alert, .badge]) { (granted, error) in
            print("requested notification")
            
            if granted {
                print("notification granted")
            } else {
                print("notification refused")
            }
        }

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

