//
//  User.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

struct User: Codable {
    
    let id: String
    let name: String
    let profileImage: String
    let email: String
    let role: Role
    var youBlocked: Bool
    var youWasBlocked: Bool
    var expert: Expert?
    var availableTime: TimeInterval
    var subscribed: Bool
    var subscribedTo: String?
    var reviews: [ReviewComment] = []
    
    var isAvailable: Bool {
        if let expert = self.expert {
            if self.role == .user {
                return true
            } else {
                return expert.available
            }
        } else {
            return true
        }
    }
}

enum Role: String, Codable {
    case unknown
    case user
    case expert
    
    static func from(key: Int32) -> Role {
        switch key {
        case 0:
            return .user
        case 1:
            return .expert
        default:
            return .unknown
        }
    }
    
    var key: Int32 {
        switch self {
        case .unknown:
            return -1
        case .user:
            return 0
        case .expert:
            return 1
        }
    }
}

extension User {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        
        var name: String = ""
        if container.contains(.name) {
            name = try container.decode(String.self, forKey: .name)
        }
        
        var profileImage: String = ""
        if container.contains(.profileImage) {
            profileImage = try container.decode(String.self, forKey: .profileImage)
        }
        
        var email: String = ""
        if container.contains(.email) {
            do {
                email = try container.decode(String.self, forKey: .email)
            } catch {
                
            }
        }

        var role = Role.unknown
        if container.contains(.role) {
            role = try container.decode(Role.self, forKey: .role)
        }

        var youBlocked = false
        if container.contains(.youBlocked) {
            youBlocked = try container.decode(Bool.self, forKey: .youBlocked)
        }

        var youWasBlocked = false
        if container.contains(.youWasBlocked) {
            youWasBlocked = try container.decode(Bool.self, forKey: .youWasBlocked)
        }

        var isSubscribed = false
        if container.contains(.subscribed) {
            isSubscribed = try container.decode(Bool.self, forKey: .subscribed)
        }

        var subscribeDate: String?
        if container.contains(.subscribedTo) {
            subscribeDate = try container.decode(String.self, forKey: .subscribedTo)
        }

        var expert: Expert?
        if container.contains(.expert) {
            do {
                expert = try container.decode(Expert.self, forKey: .expert)
            } catch let error {
                logger.log(error)
            }
        } else {
            expert = try Expert(from: decoder)
        }
        
        var availableTime = 0.0
        if container.contains(.availableTime) {
            availableTime = try container.decode(TimeInterval.self, forKey: .availableTime)
        }
        
        var reviews: [ReviewComment] = []
        if container.contains(.reviews) {
            reviews = try container.decode([ReviewComment].self, forKey: .reviews)
        }
        
        self.init(
            id: id,
            name: name,
            profileImage: profileImage,
            email: email,
            role: role,
            youBlocked: youBlocked,
            youWasBlocked: youWasBlocked,
            expert: expert,
            availableTime: availableTime,
            subscribed: isSubscribed,
            subscribedTo: subscribeDate,
            reviews: reviews
        )
    }
}
