//
//  Skill.swift
//  HipWig
//
//  Created by Alexey on 2/19/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation
import Alamofire 

struct ExpertSkillListResponse: Codable {
    let rows: [ExpertSkill]
    let pagination: Pagination
}

class ExpertSkill: NSObject, Codable {
    
    public let id: String
    public let title: String
    public let defaultImage: String
    public let selectedImage: String
    
    static let maxSkills: Int = 3
    
    init(id: String, title: String, defaultImage: String, selectedImage: String) {
        self.id = id
        self.title = title
        self.defaultImage = defaultImage
        self.selectedImage = selectedImage
        
        super.init()
    }
    
}
