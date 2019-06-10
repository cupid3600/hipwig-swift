//
//  ChatListFeatureFlagCategory.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/20/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol ChatListFeatureFlagCategory: FeatureFlagCategory {
    
    var deleteChatEnabled: Bool { get }
    var blockUserEnabled: Bool { get } 
}

final class ChatListFeatureFlagCategoryimplementation: ChatListFeatureFlagCategory {
 
    private enum ValueKey: String { 
        case deleteChatEnable = "ENABLE_DELETE_CHAT"
        case blockUserEnable = "ENABLE_BLOCK_USER"
        case unblockUserEnable = "ENABLE_UNBLOCK_USER"
    }
    private let featureFlagsService: FeatureFlagsService = FeatureFlagsServiceImplementation.defaut
    private var response: FeatureFlagServiceResponse? {
        get {
            return featureFlagsService as? FeatureFlagServiceResponse
        }
    }
    static let `default`: ChatListFeatureFlagCategoryimplementation = ChatListFeatureFlagCategoryimplementation()
    
    private init() {
        
    }
    
    var deleteChatEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.deleteChatEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
    
    var blockUserEnabled: Bool {
        if let flag = self.response?.flag(key: ValueKey.blockUserEnable.rawValue) {
            return self.value(for: flag) as? Bool ?? true
        } else {
            return true
        }
    }
}
