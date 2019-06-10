//
//  AppFlyerAnalyticsService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/23/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import AppsFlyerLib

final class AppFlyerProvider: ProviderType<AppEvent> {

    lazy var tracker = AppsFlyerTracker.shared()
    
    override init() {
        super.init()
        
        self.tracker?.appsFlyerDevKey = "w3eArqRrHfzzipyDD8DYnY"
        self.tracker?.appleAppID = "1459276585"
    }
    
    override func log(_ event: AppEvent, eventName: String, parameters: [String: Any]?) {
        switch event {
        case .receivePushToken:
            break
        case .purchase(let product, _, let price):
            let parameters = [
                AFEventParamContentId: product,
                AFEventParamRevenue: price
            ] as [String : Any]
            self.tracker?.trackEvent(AFEventPurchase, withValues: parameters)
        default:
            self.tracker?.trackEvent(eventName, withValues: parameters)
        }
    }
}


