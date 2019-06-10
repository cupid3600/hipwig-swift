//
//  Notification+Conversation.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/3/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension Notification {
    
    var conversation: Conversation? {
        guard let userInfo = self.userInfo else {
            return nil
        }
        
        return Notification.conversation(from: userInfo)
    }
    
    static func conversation(from userInfo: [AnyHashable : Any]) -> Conversation? {
        var conversation: Conversation?
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
            conversation = try JSONDecoder().decode(Conversation.self, from: jsonData)
        } catch {
            logger.log(error)
        }
        
        return conversation
    }
}
