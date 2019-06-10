//
//  CrashlyticsProvider.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/16/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Fabric
import Crashlytics

struct CrashlyticsProvider: LoggerProvider {
    
    init() {
        Fabric.with([Crashlytics.self])
    }
    
    func log(_ error: Error, userInfo: [String : Any]?) {
        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
    }
}
