//
//  AppDelegate.swift
//  HipWig
//
//  Created by Alexey on 1/15/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import GoogleSignIn
import IQKeyboardManagerSwift 
import PushKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    public let voipRegistry = PKPushRegistry(queue: .main)

    var window: UIWindow?

    private lazy var iAPPService: IAPPService = IAPPServiceImplementation.default
    private lazy var deepLinkService: DeepLinkService = DeepLinkServiceImplementation.default
    private lazy var api: RequestsManager = RequestsManager.manager
    private let callService: CallService = CallServiceImplementation.default
    private let shared: SharedStorage = SharedStorageImplementation.default
    private let pushHandler: PushService = PushHandler.handler
    private let pushRestrictions: PushRestrictionsHandler = PushRestrictionsHandler()
    private let notificationCenter: UNUserNotificationCenter = .current()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        GIDSignIn.sharedInstance()?.clientID = "28662406130-968lnrjs019mendmrvou3vg1kv2rqkah.apps.googleusercontent.com"
        
        self.registerVoipPushNotifications()
//        self.notificationCenter.delegate = pushHandler
        
        self.setupKeyboardManager()
        self.iAPPService.prepareToUse()
        
        analytics.register(provider: AppFlyerProvider())
        analytics.register(provider: MixpanelProvider(launchOptions: launchOptions))
        
        logger.register(provider: CrashlyticsProvider())
        
        if let options = launchOptions {
            if let notification = options[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
                self.pushHandler.handlePayload(info: notification, in: .none, source: .pushNotification)
            } else if let userActivityDictionary = options[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any] {
                if let userActivity = userActivityDictionary[UIApplication.LaunchOptionsKey.userActivityType] as? NSUserActivity {
                    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
                        if let route = userActivity.webpageURL?.route() {
                            self.deepLinkService.redirect(to: route.view, with: route.parameters, applicationState: .none)
                        }
                    }
                }
            } else if let notification = options[UIApplication.LaunchOptionsKey.localNotification] as? [AnyHashable : Any] {
                self.pushHandler.handlePayload(info: notification, in: .none, source: .voipNotification(false))
            }
        }
        
        return true
    }
    
    private func setupKeyboardManager() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            if let route = url.route(with: bundleIdentifier) {
                return self.deepLinkService.redirect(to: route.view, with: route.parameters, applicationState: app.eventState)
            } else {
                let handled = ApplicationDelegate.shared.application(app, open: url, options: options)
                return handled
            }
        }
        
        return false
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("[CAll] device token: \(deviceToken.tokenValue)")
        self.pushHandler.update(pushToken: deviceToken.tokenValue, type: .DEFAULT)
        
        analytics.log(.receivePushToken(token: deviceToken))
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print(userInfo)
        
        self.pushHandler.handlePayload(info: userInfo, in: application.eventState, source: .pushNotification)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if let info = notification.userInfo {
            self.pushHandler.handlePayload(info: info, in: application.eventState, source: .voipNotification(true))
        }
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let route = userActivity.webpageURL?.route() {
                return self.deepLinkService.redirect(to: route.view, with: route.parameters, applicationState: application.eventState)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication,
                     willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }
}

//MARK: - PKPushRegistryDelegate
extension AppDelegate: PKPushRegistryDelegate {
    
    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {
        print("[VOIP] device token: \(pushCredentials.token)")
        print("\(pushCredentials.token.tokenValue)")
        
        self.pushHandler.update(pushToken: pushCredentials.token.tokenValue, type: .VOIP)
    }
    
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        print(payload.dictionaryPayload)
        
        self.pushHandler.handlePayload(info: payload.dictionaryPayload, in: UIApplication.shared.eventState, source: .voipNotification(false))
        
        completion()
    }
}
