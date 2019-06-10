//
//  UIApplication+Extensions.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/16/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UIApplication {
    
    var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var version: String {
        return (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    }
    
    var buildVersion: String {
        return (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? ""
    }
    
    var applicationName: String {
        return (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? ""
    }
}

extension UIApplication {
    
    class func rootViewController() -> UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }
    
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

//MARK: Subscription recipe
extension UIApplication {
    
    var recipe: String? {
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            do {
                let data = try Data(contentsOf: receiptURL)
                return data.base64EncodedString()
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
    
    var eventState: EventReceiveState {
        let state: EventReceiveState
        
        switch self.applicationState {
        case .active:
            state = .active
        case .background:
            state = .background
        case .inactive:
            state = .inactive
        }
        
        return state
    }
    
}
