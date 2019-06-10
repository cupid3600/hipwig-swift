//
//  ExpertDetailsFeatureFlagCategory.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/20/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol ExpertDetailsFeatureFlagCategory: FeatureFlagCategory {
    
    var expertCallEnabled: Bool { get }

    var popupPricesEnabled: Bool { get }
    
    var soundEnabled: Bool { get }
    
    var stikerEnabled: Bool { get }
    
    var expertChatEnabled: Bool { get }
    
    var expertVideoEnabled: Bool { get }
    
    var freeCalls: Bool { get }
    
    var freeMessages: Bool { get }
    
    var freeMinutes: Bool { get }
    
    var becomeAnAdvisor: Bool { get }
    
    var showSubscriptionDiscount: Bool { get }
}

final class ExpertDetailsFeatureFlagCategoryImplementation: ExpertDetailsFeatureFlagCategory {
    
    private enum FlagKey: String {
        case profileShowCall = "PROFILE_SHOW_CALL"
        case profileShowVideo = "PROFILE_SHOW_VIDEO"
        case profileShowChat = "PROFILE_SHOW_CHAT"
        
        case showPopupPrices = "POPUP_PRICES"
        case soundEnable = "SOUND_ENABLE"
        case stikerEnable = "STICKER_ENABLE"

        case callSubscriptionEnable = "CALL_DISABLE_SUBSCRIPTION"
        case chatSubscriptionEnable = "CHAT_DISABLE_SUBSCRIPTION"
        case minutesSubscriptionEnable = "disable_minutes_purchasing"
        case becomeAnAdvisorEnable = "BECOME_AN_ADVISOR"
        case showSubscriptionDiscount = "SHOW_SUBSCRIPTION_DISCOUNT"
    }
    
    private let featureFlagsService: FeatureFlagsService = FeatureFlagsServiceImplementation.defaut
    
    private var response: FeatureFlagServiceResponse? {
        get {
            return featureFlagsService as? FeatureFlagServiceResponse
        }
    }
    static let `default`: ExpertDetailsFeatureFlagCategoryImplementation = ExpertDetailsFeatureFlagCategoryImplementation()
    
    private init() {
        
    }
    
    var expertCallEnabled: Bool {
        if let flag = self.response?.flag(key: FlagKey.profileShowCall.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var popupPricesEnabled: Bool {
        if let flag = self.response?.flag(key: FlagKey.showPopupPrices.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var soundEnabled: Bool {
        if let flag = self.response?.flag(key: FlagKey.soundEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var stikerEnabled: Bool {
        if let flag = self.response?.flag(key: FlagKey.stikerEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var expertChatEnabled: Bool {
        if let flag = self.response?.flag(key: FlagKey.profileShowChat.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var expertVideoEnabled: Bool {
        if let flag = self.response?.flag(key: FlagKey.profileShowVideo.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }

    var freeCalls: Bool {
        return !callSubscriptionEnable
    }
    
    var freeMessages: Bool {
        return !chatSubscriptionEnable
    }
    
    var freeMinutes: Bool {
        return !minutesSubscriptionEnable
    }
    
    private var callSubscriptionEnable: Bool {
        if let flag = self.response?.flag(key: FlagKey.callSubscriptionEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }

    private var chatSubscriptionEnable: Bool {
        if let flag = self.response?.flag(key: FlagKey.chatSubscriptionEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    private var minutesSubscriptionEnable: Bool {
        if let flag = self.response?.flag(key: FlagKey.minutesSubscriptionEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }

    var becomeAnAdvisor: Bool {
        if let flag = self.response?.flag(key: FlagKey.becomeAnAdvisorEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var showSubscriptionDiscount: Bool {
        if let flag = self.response?.flag(key: FlagKey.showSubscriptionDiscount.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
}
