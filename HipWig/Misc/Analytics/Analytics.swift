//
//  Analytics.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/23/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

public protocol AnalyticsType {
    associatedtype Event: AnalyticEvent
    func register(provider: ProviderType<Event>)
}

public class ProviderType<T> {
    func log(_ event: T, eventName: String, parameters: [String: Any]?) { }
}

public protocol AnalyticEvent {
    var name: String? { get }
    var parameters: [String: Any]? { get }
}

open class Analytics<Event: AnalyticEvent>: AnalyticsType {
    
    private(set) open var providers: [ProviderType<Event>] = []
    
    public init() {
        print("I'm Analytics 👋")
    }
    
    open func register(provider: ProviderType<Event>) {
        self.providers.append(provider)
    }
    
    open func log(_ event: Event) {
        for provider in self.providers {
            guard let eventName = event.name else { continue }
            let parameters = event.parameters

            provider.log(event, eventName: eventName, parameters: parameters)
        }
    }
}

let analytics = Analytics<AppEvent>()


