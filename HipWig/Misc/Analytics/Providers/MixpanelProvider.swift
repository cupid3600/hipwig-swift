//
//  MixpanelProvider.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/8/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Mixpanel

final class MixpanelProvider: ProviderType<AppEvent> {

    lazy var tracker = Mixpanel.sharedInstance()
    private let accout: AccountManager = AccountManager.manager
    
    private var userInfo: [String: Any] {
        return accout.userInfo
    }
    
    private var userName: String {
        if let user = accout.user {
            return user.name
        } else {
            return ""
        }
    }
    
    private var userId: String {
        if let user = accout.user {
            return user.id
        } else {
            return ""
        }
    }
    
    private var distinctId: String {
        return self.tracker?.distinctId ?? ""
    }
    
    init(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        super.init()
        Mixpanel.sharedInstance(withToken: "5e080b4a7ff2dccba432139f7106f698", launchOptions: launchOptions, trackCrashes: true, automaticPushTracking: false)
    }
    
    override func log(_ event: AppEvent, eventName: String, parameters: [String: Any]?) {
        switch event {
        case .receivePushToken(let token):
            self.tracker?.people.addPushDeviceToken(token)
        case .login:
            
            self.tracker?.createAlias(self.userName, forDistinctID: self.distinctId)
            self.tracker?.identify(self.distinctId)
            self.tracker?.people.set(self.userInfo)
            
            self.tracker?.track(eventName, properties: parameters)
        case .purchase(let product, let productType, let price):
            let amount = NSNumber(value: price)
            let parameters = [
                "product": product,
                "type": productType
            ] as [String: Any]
            
            self.tracker?.people.trackCharge(amount, withProperties: parameters)
        default:
            var properties = parameters
            if properties == nil {
                properties = [:]
            }
            
            properties?["user_name"] = self.userName
            properties?["user_id"] = self.userId
            
            self.tracker?.track(eventName, properties: properties)
        }
    } 
}
