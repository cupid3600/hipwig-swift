//
//  Purpose.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/4/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

enum Purpose: Int, CaseIterable, Codable {
    
    case advice
    case talk
    
    var value: String {
        switch self {
        case .advice:
            return "tip"
        case .talk:
            return "talk"
        }
    }
    
    var title: String {
        switch self {
        case .advice:
            return "expert_list.filter.work_type.advice".localized
        case .talk:
            return "expert_list.filter.work_type.talk".localized
        }
    }
}

extension Purpose {
    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        if container.contains(.purpose) {
//            self.purpose = try container.decode(Purpose.self, forKey: .purpose)
//        }
//    }
}
