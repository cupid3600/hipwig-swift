//
//  AppDelegate+Extensions.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/16/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import UserNotifications
import PushKit

private var notificationCenter: UNUserNotificationCenter = .current()

extension AppDelegate {

    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func prepareNotificationDelegate() {
        notificationCenter.delegate = self
    }
    
    var isRegisteredForRemoteNotifications: Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }
    
    private func setNotificationsEnabled(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: kNotificationEnable)
        UserDefaults.standard.synchronize()
    }
    
    func notificationsEnabledIfAvailable(_ value: Bool, postEvent: Bool = true, completion: @escaping (Bool) -> Void) {
        AppDelegate.shared.notificationsEnabled(postEvent){ _, isEnabledBySystem in
            if value && !isEnabledBySystem {
                ModalStoryboard.showSettingsAlert(completion: {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    
                    AppDelegate.shared.setNotificationsEnabled(value)
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl) { _ in }
                    }
                    
                    completion(value)
                    
                }, cancelAction: {
                    completion(false)
                })
                
            } else {
                AppDelegate.shared.setNotificationsEnabled(value)
                
                if value {
                    AppDelegate.shared.registerRemoteNotifications()
                } else {
                    AppDelegate.shared.unregisterRemoteNotifications()
                }
                
                completion(value)
            }
        }
    }
    
    func notificationsEnabled(_ postEvent: Bool = true, _ completion: @escaping (_ isEnabledLocally: Bool, _ isEnabledBySystem: Bool) -> Void) {
        if UserDefaults.standard.value(forKey: kNotificationEnable) == nil {
            UserDefaults.standard.set(true, forKey: kNotificationEnable)
            UserDefaults.standard.synchronize()
        }
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        notificationCenter.requestAuthorization(options: authOptions) { granted, _ in
            DispatchQueue.main.async {

                if !granted {
                    completion(false, false)
                    
                    if postEvent {
                        NotificationCenter.postNotificationStatusChangeEvent(false)
                    }
                } else {
                    let value = UserDefaults.standard.value(forKey: kNotificationEnable) as! Bool
                    if postEvent {
                        NotificationCenter.postNotificationStatusChangeEvent(value)
                    }
                    
                    completion(value, true)
                }
            }
        }
    }
    
    func unregisterRemoteNotifications() {
        UIApplication.shared.unregisterForRemoteNotifications()
    }
    
    func registerRemoteNotifications() {
        self.requestNotificationAuthorization(application: UIApplication.shared)
    }
    
    func registerVoipPushNotifications() {
        self.voipRegistry.delegate = self
        self.voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    public func registerPushNotifications() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            notificationCenter.getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized else { return }
                
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func requestNotificationAuthorization(application: UIApplication) {
        if #available(iOS 10.0, *) {
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            notificationCenter.requestAuthorization(options: authOptions) { granted, error in
                if granted {
                    self.getNotificationSettings()
                } else {
                    DispatchQueue.main.async {
                        ModalStoryboard.showSettingsAlert(completion: {
                            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            
                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                UIApplication.shared.open(settingsUrl) { _ in }
                            }
                        })
                    }
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
    }
    
    private func getNotificationSettings() {
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func cancelLocalPushNotifications(ids: [String]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    func cancelDeliveredNotifications(ids: [String]) {
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }
    
    @discardableResult
    func sendLocalPushNotificationOnce(id: String = UUID().uuidString, content: UNMutableNotificationContent) -> String {
        self.scheduleLocalPushNotification(id: id, content: content, timeInterval: 0, repeats: false)
        
        return id
    }
    
    func scheduledLocalPushNotification(id: String = UUID().uuidString, title: String = "", body: String = "", timeInterval: TimeInterval, repeats: Bool) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        self.scheduleLocalPushNotification(id: id, content: content, timeInterval: timeInterval, repeats: repeats)
    }
    
    func scheduleLocalPushNotification(_ notification: UILocalNotification) {
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    func scheduleLocalPushNotification(id: String = UUID().uuidString, content: UNMutableNotificationContent, timeInterval: TimeInterval, repeats: Bool) {
        
        let trigger = timeInterval > 0
            ? UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
            : nil
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    logger.log(error)
                } else {
                    //print("notification added")
                }
            }
        }
    }
    
    func removeScheduledLocalPushNotification(ids: [String]) {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
    
    func getDeliveredNotificationIdentifiers(completion: @escaping ([String]) -> Void, filter: @escaping (UNNotification) -> Bool) {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().getDeliveredNotifications { notications in
                let callNotifications = notications.filter { notification in
                    return filter(notification)
                }
                let result = callNotifications.map{ $0.request.identifier }
                
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }
    
//    func getIncomingCallNotificationIdentifiers(completion: @escaping ([String]) -> Void) {
//        UNUserNotificationCenter.current().getDeliveredNotifications { notications in
//            let callNotifications = notications.filter { notification in
//                let info = notification.request.content.userInfo
//                if let type = info["type"] as? String, let event = PushNotificationType(rawValue: type) {
//                    return event == .incomingCall
//                } else {
//                    return false
//                }
//            }
//            let result = callNotifications.map{ $0.request.identifier }
//            
//            completion(result)
//        }
//    }
    
//    public func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                       willPresent notification: UNNotification,
//                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([.alert, .badge, .sound])
//    }
}
