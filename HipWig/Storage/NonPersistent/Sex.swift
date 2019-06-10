//
//  Sex.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/4/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

enum Sex: Int, CaseIterable, Codable {
    
    case male
    case female
    
    var value: String {
        switch self {
        case .female:
            return "female"
        case .male:
            return "male"
        }
    }
    
    var title: String {
        switch self {
        case .female:
            return "expert_list.filter.gender.woman".localized
        case .male:
            return "expert_list.filter.gender.man".localized
        }
    }
}
