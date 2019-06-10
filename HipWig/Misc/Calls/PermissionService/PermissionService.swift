//
//  PermissionService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/27/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

enum Action {
//    case acceptCall
    case makeCall(to: User)
    case sendMessage(to: User)
}

protocol PermissionService: class {
    func check(for event: Action, completion: @escaping (Bool) -> Void)
}

class PermissionServiceImplementation: PermissionService {

    private let featureFlags = ExpertDetailsFeatureFlagCategoryImplementation.default
    private let api: RequestsManager = RequestsManager.manager
    private let account: AccountManager = AccountManager.manager
    private let productService: ProductService = ProductServiceImplementation.default
    private let flags: ExpertDetailsFeatureFlagCategory = ExpertDetailsFeatureFlagCategoryImplementation.default
    private let microphonePermissions = MicrophonePermissionsCheck()
    private let cameraPermissions = CameraPermissionsCheck()

    func check(for event: Action, completion: @escaping (Bool) -> Void) {
        switch event {
        case .makeCall(let receiver):
            let checkForAvailableMinutesClosure = { [weak self] in
                guard let `self` = self else { return }
                
                self.checkIfCanMakeCall(receiver) { isAvailable in
                    if isAvailable {
                        self.microphonePermissions.check{ _ in
                            self.cameraPermissions.check{ _ in
                                completion(isAvailable)
                            }
                        }
                    } else {
                        completion(isAvailable)
                    }
                }
            }
            
            if receiver.isAvailable {
                if self.flags.freeCalls {
                    checkForAvailableMinutesClosure()
                } else {
                    self.showSubscriptionAndReloadViewIfNeeded(receiver: receiver) { [weak self] in
                        guard let `self` = self else { return }
                        let isSubscribed = self.account.isSubscribed
                        
                        if isSubscribed {
                            checkForAvailableMinutesClosure()
                        } else {
                            completion(isSubscribed)
                        }
                    }
                }
            } else {
                ModalStoryboard.showUnavailableToCall()
                completion(false)
            }
            
        case .sendMessage(let receiver):
            if self.flags.freeMessages {
                completion(true)
            } else {
                self.showSubscriptionAndReloadViewIfNeeded(receiver: receiver) { [weak self] in
                    guard let `self` = self else { return }
                    
                    completion(self.account.isSubscribed)
                }
            }
//        default:
//            completion(true)
        }
    }
    
    private func checkForSubscription(for receiver: User, _ completion: @escaping (Bool) -> Void) {
        if receiver.isAvailable {
            if self.flags.freeCalls {
                self.checkForOwnAvailableMinutes(completion: completion)
            } else {
                self.showSubscriptionAndReloadViewIfNeeded(receiver: receiver) { [weak self] in
                    guard let `self` = self else { return }

                    completion(self.account.isSubscribed)
                }
            }

        } else {
            completion(false)
        }
    }
    
    private func checkIfCanMakeCall(_ receiver: User, completion: @escaping (Bool) -> Void) {
        if self.featureFlags.freeMinutes {
            completion(true)
        } else {
            if self.account.role == .user {
                self.checkForOwnAvailableMinutes(completion: completion)
            } else {
                self.checkForReceiverAvailableMinutes(for: receiver) { hasAvailableMinutes in
                    if !hasAvailableMinutes {
                        ModalStoryboard.showUnavailableToCallToUser()
                    }
                    
                    completion(hasAvailableMinutes)
                }
            }
        }
    }
    
    private func showSubscriptionIfNeeded(completion: @escaping (_ needUpdateRootViewController: Bool) -> Void) {
        guard let target = UIApplication.topViewController() else {
            return
        }
        
        if self.account.isSubscribed {
            completion(false)
        } else {
            if let user = self.account.user, !user.subscribed {
                MainStoryboard.showBuySubscriptionScreen(from: target, backAction: { [weak self] target, showPopup in
                    guard let `self` = self else { return }
                    
                    self.account.updateUser {
                        target.dismiss(animated: true) {
                            if showPopup {
                                self.showDiscountPupup(completion: completion)
                            }
                        }
                    }
                }) { [weak self] target in
                    guard let `self` = self else { return }
                    
                    self.account.updateUser {
                        target.dismiss(animated: true) {
                            completion(true)
                        }
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    private func showDiscountPupup(completion: @escaping (_ needUpdateRootViewController: Bool) -> Void) {
        if self.flags.showSubscriptionDiscount {
            MainStoryboard.showDiscountPopup(completion: { [weak self] in
                guard let `self` = self else { return }
                
                self.showSubscriptionIfNeeded(completion: completion)
            }, cancelAction: {
                completion(false)
            })
            
        } else {
            completion(false)
        }
    }
    
    private func showSubscriptionAndReloadViewIfNeeded(receiver: User, completion: @escaping () -> Void) {
        self.showSubscriptionIfNeeded { needUpdateRootViewController in
            if needUpdateRootViewController {
                
                MainStoryboard.showMainScreen(useAnimation: false)

                if let source = UIApplication.topViewController() {
                    MainStoryboard.showExpertProfile(from: source, expert: receiver, animated: false)
                }
            }

            completion()
        }
    }
    
//    private func showDiscountPopup(user: User, completion: @escaping (Bool) -> Void) {
//        ModalStoryboard.showDiscountPopup(title: "Limited time offer!", leftTime: self.productService.leftDiscountTime) { discountHasApplied in
//            if discountHasApplied {
//                self.checkForOwnAvailableMinutes(needShowPopup: false, completion: completion)
//            } else {
//                completion(user.availableTime > 1.0)
//            }
//        }
//    }
    
    private func checkForReceiverAvailableMinutes(for receiver: User, _ completion: @escaping (Bool) -> Void) {
        self.api.getAvailableMinutes(for: receiver.id) { result in
            var hasAvailableMinutes: Bool = false
            
            switch result {
            case .success(let hasMinutes):
                hasAvailableMinutes = hasMinutes
            case .failure(let error):
                logger.log(error)
            }
            
            completion(hasAvailableMinutes)
        }
    }
    
    private func checkForOwnAvailableMinutes(needShowPopup: Bool = true, completion: @escaping (Bool) -> Void) {
        if self.account.role == .expert {
            completion(true)
        } else {
            self.account.updateUser { [weak self] in
                guard let `self` = self else { return }
                
                if let user = self.account.user {
                    if user.availableTime > 1.0  {
                        completion(true)
                    } else {
                        if needShowPopup {
                            MainStoryboard.showAddCallCreditsPopup(callThreshold: .zero) { haveBought in
                                if haveBought {
                                    self.checkForOwnAvailableMinutes(needShowPopup: false, completion: completion)
                                } else {
                                    completion(user.availableTime > 1.0)
                                }
                            }
                            
//                            let title = "Insufficient Coins"
//                            let details = "Recharge to start video chat."
//
//                            ModalStoryboard.showAddCallCreditsPopup(title: title, details: details) { haveBought in
//                                if haveBought {
//                                    self.checkForAvailableMinutes(needShowPopup: false, completion: completion)
//                                } else {
//                                    if self.productService.showDiscountFirstTime {
//                                        self.showDiscountPopup(user: user, completion: completion)
//                                    } else {
//                                        if self.productService.discountTimedOut {
//                                            completion(user.availableTime > 1.0)
//                                        } else {
//                                            self.showDiscountPopup(user: user, completion: completion)
//                                        }
//                                    }
//                                }
//                            }
                        } else {
                            completion(user.availableTime > 1.0)
                        }
                    }
                }
            }
        }
    }

}
