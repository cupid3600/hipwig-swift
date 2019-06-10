//
//  MainStoryboard.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/6/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SafariServices
import UIWindowTransition
import SVProgressHUD

class MainStoryboard: UIStoryboard {
    
    class var startViewController: UIViewController {
        return instance.instantiateInitialViewController()!
    }
    
    class func showAddCallCreditsPopup(callThreshold: CallThreshold? = nil,
                                       callCaption: String? = nil,
                                       whileInCallingState: Bool = false,
                                       completion: @escaping (Bool) -> Void) {
        
        let viewController: AddCallCreditsPopupViewController = instantiate()

        viewController.callThreshold = callThreshold
        viewController.completion = completion
        viewController.whileInCallingState = whileInCallingState
        viewController.callCaption = callCaption

        if let target = UIApplication.topViewController() {
            if target is AddCallCreditsPopupViewController {
                target.dismiss(animated: false) {
                    self.showPopup(viewController)
                }
            } else {
                self.showPopup(viewController)
            }
        }
        
//        let viewController: AddCoinsPopupViewController = instantiate()
//
////        viewController.callThreshold = callThreshold
//        viewController.completion = completion
////        viewController.whileInCallingState = whileInCallingState
//        viewController.titleText = callCaption
//
//        if let target = UIApplication.topViewController() {
//            if target is AddCoinsPopupViewController {
//                target.dismiss(animated: false) {
//                    self.showPopup(viewController)
//                }
//            } else {
//                self.showPopup(viewController)
//            }
//        }
    }

    class func showBuySubscriptionScreen(from source: UIViewController,
                                         backAction: ((BaseViewController, Bool) -> Void)?,
                                         completion: ((BaseViewController) -> Void)?) {
        
        let viewController: SubscriptionPlansViewController = instantiate()
        
        viewController.backAction = backAction
        viewController.completionAction = completion
        
        source.present(viewController, animated: true) 
    }

    class func showDiscountPopup(completion: @escaping (() -> Void), cancelAction: @escaping () -> Void) {
        
        let viewController: DiscountPopupViewController = instantiate()
        
        viewController.purchaseCompletion = completion
        viewController.cancelAction = cancelAction
        
        self.showPopup(viewController)
    }
    
    class func showExpertProfile(from source: UIViewController, expert: User, animated: Bool = true) {
        
        let viewController: ExpertDetailsViewController = instantiate()
        viewController.expert = expert
        viewController.hidesBottomBarWhenPushed = true

        source.navigationController?.pushViewController(viewController, animated: animated)
    }
    
    class func showConversation(from source: UINavigationController, with expert: User) {
        
        let viewController: ConversationViewController = instantiate(customID: kConversationScreenID)
        
        viewController.opponentId = expert.id
        viewController.hidesBottomBarWhenPushed = true
        
        source.pushViewController(viewController, animated: true)
    }
    
    class func showLogin() {
        let viewController: LoginViewController = instantiate(customID: kLoginScreenID)
        
        if let window = AppDelegate.shared.window {
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.setNavigationBarHidden(true, animated: false)
            
            let transition = UIWindow.Transition(style: .fade)
            window.transition(transition, to: navigationController)
        }
    }
    
    class func showMainScreen(useAnimation: Bool = true) {
        let category = ExpertDetailsFeatureFlagCategoryImplementation.default
        
        if let user = AccountManager.manager.user {
            var viewController: UIViewController
        
            let isFreePlan = category.freeCalls || category.freeMessages
            
            if user.role == .user && user.subscribed || user.role == .expert || isFreePlan {
                let source: TabBarViewController = MainStoryboard.instantiate(customID: kRootTabBarControllerID)
                viewController = source
            } else {
                let source: UINavigationController = MainStoryboard.instantiate(customID: kRootNavigationControllerID)
                viewController = source
            }
            
            if let window = AppDelegate.shared.window {
                let transition = UIWindow.Transition(style: useAnimation ? .flipFromLeft : .none)
                window.transition(transition, to: viewController)
            }
        }
    }
    
    class var mainScreenAsTabBar: Bool {
        get {
            if let window = AppDelegate.shared.window {
                return window.rootViewController is UITabBarController
            } else {
                return false
            }
        }
    }
    
    class var tabBarViewController: TabBarViewController? {
        get {
            if let window = AppDelegate.shared.window {
                return window.rootViewController as? TabBarViewController
            } else {
                return nil
            }
        }
    }
    
    class var isChatSelected: Bool {
        get {
            if let target = UIApplication.topViewController() {
                return target is ConversationViewController
            } else {
                return false
            }
        }
    }
    
    class func showExpertListIfAvailable() {
        if MainStoryboard.mainScreenAsTabBar {
            if let target = MainStoryboard.tabBarViewController {
                target.selectedIndex = 0
                
                if let navigationController = target.selectedViewController as? UINavigationController {
                    navigationController.popToRootViewController(animated: false)
                }
            }
        }
    }
    
    class func showChatListIfAvailable() {
        if MainStoryboard.mainScreenAsTabBar {
            if let target = MainStoryboard.tabBarViewController {
                target.selectedIndex = 1
                
                if let navigationController = target.selectedViewController as? UINavigationController {
                    navigationController.popToRootViewController(animated: false)
                }
            }
        }
    }
}

extension UIStoryboard {
    class func showPopup(_ viewController: UIViewController, window: UIWindow? = UIApplication.shared.keyWindow) {
        
        if let target = UIApplication.topViewController(controller: window?.rootViewController) {
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            
            target.present(viewController, animated: true)
        }
    }
}
