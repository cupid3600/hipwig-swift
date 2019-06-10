//
//  ManagedExpertSkill+CoreDataClass.swift
//  
//
//  Created by Vladyslav Shepitko on 5/23/19.
//
//

import Foundation
import CoreData

@objc(ManagedExpertSkill)
public class ManagedExpertSkill: NSManagedObject {
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var defaultImage: String?
    @NSManaged public var selectedImage: String?
    
    convenience init(worker: NSManagedObjectContext, skill: ExpertSkill) {
        self.init(context: worker)
        self.id = skill.id
        self.title = skill.title
        self.defaultImage = skill.defaultImage
        self.selectedImage = skill.selectedImage
    }
    
    var skillValue: ExpertSkill? {
        guard let id = self.id else {
            return nil
        }
        
        return ExpertSkill(id: id, title: "String", defaultImage: "String", selectedImage: "String") 
    }
}
