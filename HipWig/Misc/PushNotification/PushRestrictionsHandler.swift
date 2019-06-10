//
//  PushRestrictionsHandler.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/6/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class PushRestrictionsHandler: NSObject {
    
    public func canPerform(for opponent: String?, currentOpponent: String?) -> Bool {
        if (opponent != nil && opponent != currentOpponent) && currentOpponent != nil {
            return false
        }
        
        return true
    }
    
//    public func canResetPush(for userInfo: [AnyHashable : Any], currentOpponent: String?) -> Bool {
//        guard let type = userInfo["type"] as? String, let event = PushNotificationType(type) else {
//            return false
//        }
//        
//        switch event {
//        case .call(let callEvent):
//            if callEvent == .endCall {
//                let opponent = userInfo["userId"] as? String
//                return canPerform(for: opponent, currentOpponent: currentOpponent)
//            } else {
//                return false
//            }
//        default:
//            return false
//        }
//    }
}
