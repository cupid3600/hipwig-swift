//
//  Event.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import UserNotifications

struct LocalNotificationContent {
    
    let title: String
    let body: String
    let info: [AnyHashable : Any]?
    
    init(title: String, body: String, info: [AnyHashable : Any]?) {
        self.title = title
        self.body = body
        self.info = info
    }
    
    init?(info: [AnyHashable : Any]) {
        guard let aps = info["aps"] as? [AnyHashable : Any] else {
            return nil
        }
        
        guard let title = aps["alert"] as? String else {
            return nil
        }
        
        self.info = info
        self.title = title
        self.body = ""
    }
    
    var notificationContent: UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = self.title
        content.body = self.body
        
        if let aps = info?["aps"] as? [AnyHashable : Any] {
            let sound = aps["sound"] as? String ?? "Opening.m4r"
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
        }
        content.userInfo = self.info ?? [:]
        
        return content
    }
    
    var localNotification: UILocalNotification {
        var notification = UILocalNotification()
        
        notification.alertTitle = self.title
        notification.alertBody = self.body
        notification.userInfo = self.info ?? [:]
        
        if let aps = info?["aps"] as? [AnyHashable : Any] {
            notification.soundName = aps["sound"] as? String ?? "Opening.m4r"
        }
        
        return notification
    }
    
    static var VideoUploaded: LocalNotificationContent {
        return LocalNotificationContent(title: "Your profile video has been uploaded", body: "", info: nil)
    }
    
    static var ProfilePhotoUploaded: LocalNotificationContent {
        return LocalNotificationContent(title: "Your profile photo has been uploaded", body: "", info: nil)
    }
}  
