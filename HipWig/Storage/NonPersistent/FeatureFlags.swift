//
//  Result.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/5/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

struct FeatureFlagListResponse: Codable {
    let rows: [FeatureFlag]
    let pagination: Pagination
}

struct FeatureFlag: Codable {
    
    let id: String
    let title: String
    let key: String
    let value: FeatureFlagValue
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.key = try container.decode(String.self, forKey: .key)
        self.value = try FeatureFlagValue(from: decoder)
        self.title = try container.decode(String.self, forKey: .title)
    }
}

enum FeatureFlagValue: Codable {
    
    case boolean(Bool)
    case int(Int)
    case string(String)
    case undefined
    
    enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type: String = try container.decode(String.self, forKey: .type)
        let value: String = try container.decode(String.self, forKey: .value)
        let stringValue = NSString(string: value)
        
        
        switch type {
        case FeatureFlagValueKey.boolean.rawValue:
            self = .boolean(stringValue.boolValue)
        case FeatureFlagValueKey.int.rawValue:
            self = .int(stringValue.integerValue)
        case FeatureFlagValueKey.string.rawValue:
            self = .string(value)
        default:
            self = .undefined
        }
    }
    
    func encode(to encoder: Encoder) throws {
        
    }
    
    private enum FeatureFlagValueKey: String {
        case boolean = "boolean"
        case int = "intValue"
        case string = "FeatureStringValue"
    }
}
