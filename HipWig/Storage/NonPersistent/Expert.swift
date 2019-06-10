//
//  Expert.swift
//  HipWig
//
//  Created by Alexey on 1/18/19.
//  Copyright © 2019 HipWig. All rights reserved.
//
import Foundation

struct ExpertListResponse: Codable {
    let rows: [User]
    let pagination: Pagination
}

struct Expert: Codable {
    let id: String
    
    let name: String
    let gender: Gender
    let profileImage: String?
    var profileVideo: String?
    let paypalAccount: String?
    let workType: WorkType
    let location: String?
    let followers: Int
    let available: Bool
    let skills: [ExpertSkill]
    let clients: Int
    let publicProfile: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case gender
        case name
        case profileImage
        case profileVideo
        case workType
        case location
        case followers
        case available
        case skills
        case paypalAccount
        case clients
        case publicProfile
    }

    public func skillIDs() -> [String] {
        return self.skills.map{ $0.id }
    }
}

enum Gender: String, Codable {
    case female = "female"
    case male = "male"
}

enum Skill: String, Codable {
    case dating = "Dating"
    case fun = "Fun"
    case relationships = "Relationships"
}

enum WorkType: String, Codable {
    case talk = "talk"
    case tip = "tip"
    
    static func from(key: Int32) -> WorkType {
        if key == 0 {
            return .talk
        } else {
            return .tip
        }
    }
    
    var key: Int32 {
        switch self {
        case .talk:
            return 0
        case .tip:
            return 1
        }
    }
}

extension Expert {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        
        var profileImage: String? = nil
        if container.contains(.profileImage) {
            profileImage = try container.decode(String.self, forKey: .profileImage)
        }

        var gender = Gender.male
        if container.contains(.gender) {
            gender = try container.decode(Gender.self, forKey: .gender)
        }

        var profileVideo: String? = nil
        if container.contains(.profileVideo) {
            profileVideo = try? container.decode(String.self, forKey: .profileVideo)
        }

        var workType = WorkType.talk
        if container.contains(.workType) {
            workType = try container.decode(WorkType.self, forKey: .workType)
        }

        var location = ""
        if container.contains(.location) {
            location = try container.decode(String.self, forKey: .location)
        }

        var followers = 0
        if container.contains(.followers) {
            followers = try container.decode(Int.self, forKey: .followers)
        }

        var available = false
        if container.contains(.available) {
            available = try container.decode(Bool.self, forKey: .available)
        }

        var skills: [ExpertSkill]? = nil
        if container.contains(.skills) {
            skills = try? container.decode([ExpertSkill].self, forKey: .skills)
        }
        
        var paypalAccount: String? = nil
        if container.contains(.paypalAccount) {
            paypalAccount = try? container.decode(String.self, forKey: .paypalAccount)
        }

        var clientsNum: Int = 0
        if container.contains(.clients) {
            clientsNum = try container.decode(Int.self, forKey: .clients)
        }

        var isPublic = true
        if container.contains(.publicProfile) {
            isPublic = try container.decode(Bool.self, forKey: .publicProfile)
        }

        self.init(id: id, name: name, gender: gender, profileImage: profileImage, profileVideo: profileVideo, paypalAccount: paypalAccount, workType: workType, location: location, followers: followers, available: available, skills: skills ?? [], clients: clientsNum, publicProfile: isPublic)
    }
}
