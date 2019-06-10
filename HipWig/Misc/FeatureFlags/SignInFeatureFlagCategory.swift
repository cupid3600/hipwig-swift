//
//  SignInFeatureFlagCategory.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/20/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol SignInFeatureFlagCategory: FeatureFlagCategory {
    
    var facebookLoginEnabled: Bool { get }
    var googleLoginEnabled: Bool { get }
    var instagramLoginEnabled: Bool { get }
}

final class SignInFeatureFlagCategoryImplementation: SignInFeatureFlagCategory {
    private enum ValueKey: String {
        case instagramEnable = "INSTAGRAM_ENABLE"
        case googleEnable = "GOOGLE_ENABLE"
        case facebookEnable = "FACEBOOK_ENABLE"
    }
    
    private let featureFlagsService: FeatureFlagsService = FeatureFlagsServiceImplementation.defaut
    
    private var response: FeatureFlagServiceResponse? {
        get {
            return featureFlagsService as? FeatureFlagServiceResponse
        }
    }

    static let `default`: SignInFeatureFlagCategoryImplementation = SignInFeatureFlagCategoryImplementation()
    
    var facebookLoginEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.facebookEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }

    var googleLoginEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.googleEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }

    var instagramLoginEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.instagramEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? false
        } else {
            return false
        }
    }
}
