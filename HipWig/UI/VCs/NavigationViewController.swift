//
//  NavigationViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/27/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController {

    private let pushHandler: PushHandler = PushHandler.handler
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppDelegate.shared.notificationsEnabled { [weak self] isEnabled, _ in
            guard let `self` = self else { return }
            
            if isEnabled {
                AppDelegate.shared.registerPushNotifications()
            }
            
            if let token = AppDelegate.shared.voipRegistry.pushToken(for: .voIP) {
                self.pushHandler.update(pushToken: token.tokenValue, type: .VOIP)
            }
        }
    }
}
