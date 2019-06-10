//
//  JWT+ExpireSoon.swift
//  Reinforce
//
//  Created by Vladyslav Shepitko on 4/5/19.
//  Copyright © 2019 Sonerim. All rights reserved.
//

import UIKit
import JWTDecode

extension JWT {
    
    var expireSoon: Bool {
        if let expireDate = self.expiresAt {
            let nowDateValue = Date().timeIntervalSince1970
            let expireDateValue = expireDate.timeIntervalSince1970
            let difference = expireDateValue - nowDateValue
            
            if difference > 0 {
                return expireDateValue <= 60.0 * 10.0
            } else {
                return true
            }
        } else {
            return false
        }
    }
    
}

extension String {
    
    var JWTtokenStatus: AccessTokenStatus {
        let accessToken = self
        if accessToken.isEmpty {
            return .absent
        } else {
            do {
                let token = accessToken.replacingOccurrences(of: "Bearer ", with: "")
                let jwt = try decode(jwt: token)
                
                if jwt.expired {
                    return .expired
                } else if jwt.expireSoon {
                    return .expireSoon
                }
                
                return .working
            } catch {
                return .absent
            }
        }
    }
}
