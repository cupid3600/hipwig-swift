//
//  Logger.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/16/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol LoggerProvider {
    func log(_ error: Error, userInfo: [String : Any]?)
}

class Logger {
    private(set) open var providers: [LoggerProvider] = []
    
    public init() {
        print("I'm smart loger 👋")
    }
    
    open func register(provider: LoggerProvider) {
        self.providers.append(provider)
    }
    
    open func log(_ error: Error, userInfo: [String: Any]? = nil) {
        if UIApplication.shared.isDebug {
            print(error.localizedDescription)
        }
        
        for provider in self.providers {
            provider.log(error, userInfo: userInfo)
        }
    }

}

let logger = Logger()
