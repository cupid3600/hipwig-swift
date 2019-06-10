//
//  SettingsFeatureFlagCategory.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/20/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol SettingsFeatureFlagCategory: FeatureFlagCategory {
    
    var becomeExpertEnabled: Bool { get }
    var logoutEnabled: Bool { get }
}

final class SettingsFeatureFlagCategoryImplementation: SettingsFeatureFlagCategory {
    private enum FlagKey: String {
        case logout = "LOGOUT"
        case showBecomeExpert = "BECOME_EXPERT"
    }
    private let featureFlagsService: FeatureFlagsService = FeatureFlagsServiceImplementation.defaut
    
    private var response: FeatureFlagServiceResponse? {
        get {
            return featureFlagsService as? FeatureFlagServiceResponse
        }
    }
    static let `default`: SettingsFeatureFlagCategoryImplementation = SettingsFeatureFlagCategoryImplementation()
    
    private init() {
        
    }
    
    //MARK: - Settings
    var becomeExpertEnabled: Bool {
        if let flag = self.response?.flag(key: FlagKey.showBecomeExpert.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var logoutEnabled: Bool {
        if let flag = self.response?.flag(key: FlagKey.logout.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
}
