//
//  ModalStoryboard.swift
//  Reinforce
//
//  Created by Vladyslav Shepitko on 3/5/19.
//  Copyright © 2019 Sonerim. All rights reserved.
//

import UIKit
import AVKit
import NotificationBannerSwift
import SVProgressHUD
import SafariServices

class ModalStoryboard: UIStoryboard {

    class var errorPopover: Popover {
        return instance.instantiate()
    }
    
    class func showAddCallCreditsPopup(title: String, details: String, completion: @escaping (Bool) -> Void) {
        
        let viewController: AddCoinsPopupViewController = instantiate()
        
        viewController.completion = completion
        viewController.titleText = title
        viewController.detailsText = details
        
        if let target = UIApplication.topViewController() {
            if target is AddCoinsPopupViewController {
                target.dismiss(animated: false) {
                    self.showPopup(viewController)
                }
            } else {
                self.showPopup(viewController)
            }
        }
    }
    
    class func showDiscountPopup(title: String, leftTime: TimeInterval, completion: @escaping (Bool) -> Void) {
        
        let viewController: CoinDiscountPopupViewController = instantiate()
        
        viewController.completion = completion
        viewController.leftTime = leftTime
        viewController.titleText = title
        
        if let target = UIApplication.topViewController() {
            if target is CoinDiscountPopupViewController {
                target.dismiss(animated: false) {
                    self.showPopup(viewController)
                }
            } else {
                self.showPopup(viewController)
            }
        }
    }
    
    class func showUnavailablePurchase() {
        let title = "Purchasing is unavailable.".localized
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel))
        
        if let source = UIApplication.topViewController() {
            source.present(alert, animated: true)
        }
    }
    
    class func showUnavailableToMakeCall() {
        let title = "User doesn't have enough credits.".localized
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel))
        
        if let source = UIApplication.topViewController() {
            source.present(alert, animated: true)
        }
    }
    
    class func showUnavailableNetwork() {
        SVProgressHUD.showError(withStatus: "The Internet connection appears to be offline.")
        SVProgressHUD.dismiss(withDelay: 2.0)
    }
    
    class func show(error: String, title: String = "Error".localized) {
        let alert = UIAlertController(title: title, message: error, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel))
        
        if let source = UIApplication.topViewController() {
            source.present(alert, animated: true)
        }
    }
    
    class func showBlockChatError() {
        
        let alert = UIAlertController(title: "chat.block_chat_error".localized, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel))
        
        if let source = UIApplication.topViewController() {
            source.present(alert, animated: true)
        }
    }
    
    class func showUnblockChatError() {
        
        let alert = UIAlertController(title: "chat.unblock_chat_error".localized, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel))
        
        if let source = UIApplication.topViewController() {
            source.present(alert, animated: true)
        }
    }
    
    class func showDeleteChatError() {
        
        let alert = UIAlertController(title: "chat.delete_chat_error".localized, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel))
        
        if let source = UIApplication.topViewController() {
            source.present(alert, animated: true)
        }
    }
    
    class func showPauseCall(on window: UIWindow?, closeButtonFrame: CGRect, closeSelectedClosure: @escaping () -> Void) {
        let rootViewController = UIApplication.topViewController(controller: window?.rootViewController)
        
        if let _ = rootViewController as? PauseCallViewController {
            return
        }
//        if !PauseCallViewController.hasDisplayedPauseView {
            let target: PauseCallViewController = instantiate()
            target.closeButtonFrame = closeButtonFrame
            target.closeSelectedClosure = closeSelectedClosure
        
            if let source = rootViewController {
                target.modalTransitionStyle = .crossDissolve
                target.modalPresentationStyle = .overCurrentContext
                
//                source.place(viewController: target, on: source.view)
                source.present(target, animated: true)
            }
//        }
    }
    
    class func hidePauseCall(on window: UIWindow?, animated: Bool = true) {
        if let source = UIApplication.topViewController(controller: window?.rootViewController) {
            if let target = source as? PauseCallViewController {
                target.hide(animated: animated)
            }
        }
    }
    
    class func showMessageNotification(with conversation: Conversation, selectedAction: @escaping () -> Void ) {
        if let view = IncomingMesageBannerView.fromXib() {
            view.update(with: conversation)
            
            let banner = NotificationBanner(customView: view)
            banner.onTap = { [weak banner] in
                banner?.dismiss()
                
                selectedAction()
            }
            
            if let target = UIApplication.topViewController() {
                banner.show(queuePosition: .back, bannerPosition: .top, on: target)
            }
        }
    }
    
    class func showCoinList() {
        let target: CoinsListViewController = instantiate()
        
        if let source = UIApplication.topViewController() {
            target.modalPresentationStyle = .overFullScreen
            
            source.present(target, animated: true)
        }
    }
    
    class func showCallNotification(with user: User) {
        if let view = IncomingCallBannerView.fromXib() {
            view.update(with: user)
            
            let banner = NotificationBanner(customView: view)
            
            if let target = UIApplication.topViewController() {
                banner.show(queuePosition: .back, bannerPosition: .top, on: target)
            } 
        }
    }
    
    class func showUnavailableToCall() {
        let title = "expert_details.unavaileble_to_call".localized
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel))
        
        if let source = UIApplication.topViewController() {
            source.present(alert, animated: true)
        }
    }
    
    class func showUnavailableToCallToUser() {
        let title = "expert_details.unavaileble_to_call_to_user".localized
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel))
        
        if let source = UIApplication.topViewController() {
            source.present(alert, animated: true)
        }
    }
    
    class func showDirectionsWarningAlert() {
        let controller = UIAlertController(title: "Warning", message: "You must select 3 directions", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .cancel))
    
        if let target = UIApplication.topViewController() {
            target.present(controller, animated: true)
        }
    }
    
    class func showSettingsAlert(completion: @escaping () -> Void, cancelAction: (() -> Void)? = nil) {
        let controller = UIAlertController(title: "Push notification is unavailable! Please go to Settings and allow notifications",
                                           message: nil,
                                           preferredStyle: .alert)
        controller.addAction(
            UIAlertAction(title: "Cancel", style: .default) { _ in
            cancelAction?()
        }
        )
        
        controller.addAction(
            UIAlertAction(title: "Settings", style: .cancel) { _ in
            completion()
        }
        )
        
        if let target = UIApplication.topViewController() {
            target.present(controller, animated: true)
        }
    }
    
    class func showUnavailableAcceptCall() {
        let controller = UIAlertController(title: "Unavailable to accept incoming call", message: nil, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        if let target = UIApplication.topViewController() {
            target.present(controller, animated: true)
        }
    }
    
    class func showUnavailableSendMessage() {
        let controller = UIAlertController(title: "Unavailable to send email message", message: nil, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        if let target = UIApplication.topViewController() {
            target.present(controller, animated: true)
        }
    }
    
    class func showSupportMessageWasntSentWarning() {
        let controller = UIAlertController(title: "Your mail message hasn't sent", message: nil, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        if let target = UIApplication.topViewController() {
            target.present(controller, animated: true)
        }
    }
    
    class func showVideoPermissionDeniedAlert() {
        let alert = UIAlertController(title: "common.warning".localized,
                                      message: "common.enable_video".localized,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "common.ok".localized, style: .default, handler: nil)
        alert.addAction(okAction)
        
        if let target = UIApplication.topViewController() {
            target.present(alert, animated: true)
        }
    }
    
    class func showSelectImageView(cameraSourceClosure: @escaping () -> Void, photoSourceClosure: @escaping () -> Void) {
        let controller = UIAlertController(title: nil, message: "photo_library.title".localized, preferredStyle: .actionSheet)

        let cameraAction = UIAlertAction(title: "photo_library.camera_title".localized, style: .default) { action in
            cameraSourceClosure()
        }
        
        let photoAction = UIAlertAction(title: "photo_library.proto_library".localized, style: .default) { action in
            photoSourceClosure()
        }
        
        let cancelAction = UIAlertAction(title: "common.cancel".localized, style: .cancel)
        
        controller.addAction(cameraAction)
        controller.addAction(photoAction)
        controller.addAction(cancelAction)
        
        if let target = UIApplication.topViewController() {
            target.present(controller, animated: true)
        }
    }
    
    class func showRoleChange() {
        SVProgressHUD.showInfo(withStatus: "Your user role has been changed. Please relogin")
        SVProgressHUD.dismiss(withDelay: 5.0)
    }
    
    class func showWEBView(with url: URL, from sourse: UIViewController) {
        if url.isValidURL && UIApplication.shared.canOpenURL(url) {
            let svc = SFSafariViewController(url: url)
            sourse.present(svc, animated: true)
        }
        
//        if url.isValidURL && UIApplication.shared.canOpenURL(url) {
//            let viewController: WebViewController = instantiate()
//
//            viewController.title = ""
//            viewController.url = url
//
//            let nvc = UINavigationController(rootViewController: viewController)
//            sourse.present(nvc, animated: true)
//        }
    }
 }


