//
//  ExpertListFeatureCategory.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/20/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol ExpertListFeatureCategory: FeatureFlagCategory {
    
    var filtersEnabled: Bool { get }
    var locationFilterEnabled: Bool { get }
    var genderFilterEnabled: Bool { get }
    var workTypeFilterEnabled: Bool { get }
    var playExpertsVideoEnabled: Bool { get }
    
}

final class ExpertListFeatureCategoryImplementation: ExpertListFeatureCategory {

    private enum ValueKey: String {
        case expertShowVideo = "EXPERT_SHOW_VIDEO"
        case locationFilterEnable = "LOCATION_FILTER"
        case genderFilterEnable = "GENDER_FILTER"
        case workTypeFilterEnable = "WORK_TYPE_FILTER"
        case filtersEnable = "FILTER_ENABLE"
    }
    
    private let featureFlagsService: FeatureFlagsService = FeatureFlagsServiceImplementation.defaut
    private var response: FeatureFlagServiceResponse? {
        get {
            return self.featureFlagsService as? FeatureFlagServiceResponse
        }
    }
    static let `default`: ExpertListFeatureCategoryImplementation = ExpertListFeatureCategoryImplementation()

    private init() {
        
    }

    var locationFilterEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.locationFilterEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var genderFilterEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.genderFilterEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var workTypeFilterEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.workTypeFilterEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var filtersEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.filtersEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var playExpertsVideoEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.expertShowVideo.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
}
