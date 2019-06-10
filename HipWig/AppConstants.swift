//
//  AppConstants.swift
//  HipWig
//
//  Created by Alexey on 1/15/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

let kRootTabBarControllerID = "RootTabBarControllerID"
let kRootNavigationControllerID = "kRootNavigationControllerID"

let kConversationScreenID = "ConversationScreenID"
let kLoginScreenID = "LoginScreenID"
let kSubsriptionScreenID = "SubsriptionScreenID"
let kStartStreamScreenID = "StartStreamScreenID"
let kStreamScreenID = "StreamScreenID"
let kAcceptStreamScreenID = "AcceptStreamScreenID"

enum Enviroment {
    case development
    case production
    case localAlex
    case localMisha
    
    var socketURLString: String {
        switch self {
        case .development:
            return "http://52.90.195.110:4000/"
        case .production:
            return "http://ec2-50-17-25-102.compute-1.amazonaws.com:4000"
        case .localAlex:
            return "http://192.168.88.39:4000/"
        case .localMisha:
            return "http://192.168.88.23:4000/"
        }
    }
    
    var baseURLString: String {
        switch self {
        case .development:
            return "http://52.90.195.110:4000/"
        case .production:
            return "http://ec2-50-17-25-102.compute-1.amazonaws.com:4000"
        case .localAlex:
            return "http://192.168.88.39:4000/"
        case .localMisha:
            return "http://192.168.88.23:4000/"
        }
    }
    
    var baseURL: URL {
        return URL(string: self.baseURLString)!
    }
    
    var socketURL: URL {
        return URL(string: self.socketURLString)!
    }
}

let environment: Enviroment = .production

let kTokBoxKeyAPI = "46259502"
let kNotificationEnable = "kNotificationEnableKey"
let kFirstCallShowed = "kFirstCallShowedKey"
let kSharedDefaults = "group.ios.hipwig.app"

let kNotificationTimeOut: TimeInterval = 30.0
let kOutgoingCallTimeOut: TimeInterval = 30.0
let kIncomingCallTimeOut: TimeInterval = 60.0

extension Notification.Name {
    
    static let ChatTextViewContentSizeDidChanged = Notification.Name("ChatTextViewContentSizeDidChangeNotification")
    static let AcceptCallAction = Notification.Name("AcceptCallAction")
    static let DeclineCallAction = Notification.Name("DeclineCallAction")
    static let EndCallAction = Notification.Name("EndCallAction")
    static let PauseCallAction = Notification.Name("PauseCallAction")
    static let ResumeCallAction = Notification.Name("ResumeCallAction")
    
    static let BlockUserAction = Notification.Name("BlockUserAction")
    static let UnBlockUserAction = Notification.Name("UnBlockUserAction")
    static let RoleChangeAction = Notification.Name("RoleChangeAction")
    static let DestroyCallWindowAction = Notification.Name("DestroyCallWindowAction")
    static let WillDestroyCallWindowAction = Notification.Name("DestroyCallWindowAction")
    static let DisplayCallWindowAction = Notification.Name("DisplayCallWindowAction")
    static let IncomingTextMesage = NSNotification.Name("IncomingTextMesage")
    static let OpeningChat = NSNotification.Name("OpeningChat")
    static let MainScreenLoaded = NSNotification.Name("MainScreenLoaded")
    static let CheckForIncomingCallAction = NSNotification.Name("CheckForIncomingCallAction")
    static let NotificationStateChangeAction = NSNotification.Name("NotificationStateChangeAction")
}

extension UserDefaults {
    
    class var firstCallViewShown: Bool {
        return UserDefaults.standard.bool(forKey: kFirstCallShowed)
    }
    
    class func setFirstCallViewAsShown() {
        UserDefaults.standard.set(true, forKey: kFirstCallShowed)
        UserDefaults.standard.synchronize()
    }
}


