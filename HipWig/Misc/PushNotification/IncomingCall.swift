//
//  IncomingCall.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/6/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

struct IncomingCall: Codable {
    
    let session: String
    let token: String
    let opponent: String
    
    init?(info: [AnyHashable : Any]) {
        guard
            let session = info["sessionId"] as? String,
            let token = info["tokenId"] as? String,
            let opponent = info["partnerId"] as? String else {
                
            return nil
        }
        
        self.opponent = opponent
        self.session = session
        self.token = token
    }
    
    init() {
        self.session = String()
        self.token = String()
        self.opponent = String()
    }
    
    static var empty: IncomingCall {
        return IncomingCall()
    }
    
    static func canParse(info: [AnyHashable : Any]) -> Bool {
        return IncomingCall(info: info) != nil
    }
}
