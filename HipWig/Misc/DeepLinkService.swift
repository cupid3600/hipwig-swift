//
//  DeepLinckService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/9/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol DeepLinkService: class {
    @discardableResult
    func redirect(to view: String, with parameters: [String: String], applicationState state: EventReceiveState) -> Bool
}

class DeepLinkServiceImplementation : DeepLinkService {
    
    static let `default` = DeepLinkServiceImplementation()
    private let account: AccountManager = AccountManager.manager
    private let api: RequestsManager = RequestsManager.manager
    
    func redirect(to view: String, with parameters: [String: String], applicationState state: EventReceiveState) -> Bool {
        
        if self.account.myUserID == nil {
            self.api.unarchiveUserData()
        }
        
        if self.account.myUserID == nil {
            return false
        }
        
        if view == "become_an_expert" {
            if state == .none {
                NotificationCenter.addMainScreenDidLoadedObserver {
                    if let source = UIApplication.topViewController() {
                        BecomeAnExpertStoryboard.showStartBecomeAnExpert(from: source)
                    }
                }
            } else {
                if MainStoryboard.mainScreenAsTabBar {
                    if let source = UIApplication.topViewController() {
                        BecomeAnExpertStoryboard.showStartBecomeAnExpert(from: source)
                    }
                } else {
                    NotificationCenter.addMainScreenDidLoadedObserver {
                        if let source = UIApplication.topViewController() {
                            BecomeAnExpertStoryboard.showStartBecomeAnExpert(from: source)
                        }
                    }
                }
            } 
            
            return true
        }
        
        return false
    }
}
