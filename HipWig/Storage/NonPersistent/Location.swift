//
//  Location.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/4/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

enum Location: Int, CaseIterable, Codable {
    
    case local
    case world
    
    var value: String {
        switch self {
        case .local:
            return "local"
        case .world:
            return "world_wide"
        }
    }
    
    var title: String {
        switch self {
        case .local:
            return "expert_list.filter.location.local".localized
        case .world:
            return "expert_list.filter.location.world".localized
        }
    }
}
