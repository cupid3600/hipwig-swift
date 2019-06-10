//
//  ManagedExpert+CoreDataClass.swift
//  
//
//  Created by Vladyslav Shepitko on 5/23/19.
//
//

import Foundation
import CoreData

@objc(ManagedExpert)
public class ManagedExpert: NSManagedObject {
    
    @NSManaged public var available: Bool
    @NSManaged public var clients: Int32
    @NSManaged public var followers: Int32
    @NSManaged public var id: String?
    @NSManaged public var isPublic: Bool
    @NSManaged public var location: String?
    @NSManaged public var name: String?
    @NSManaged public var paypalAccount: String?
    @NSManaged public var profileImage: String?
    @NSManaged public var profileVideo: String?
    @NSManaged public var workTypeValue: Int32
    @NSManaged public var skills: NSSet?
    @NSManaged public var user: ManagedUser?
    
    convenience init(worker: NSManagedObjectContext, expert: Expert, user: ManagedUser?) {
        self.init(context: worker)
        
        self.id = expert.id
        self.name = expert.name
        self.profileImage = expert.profileImage
        self.profileVideo = expert.profileVideo
        self.paypalAccount = expert.paypalAccount
        self.workTypeValue = expert.workType.key
        self.location = expert.location
        self.followers = Int32(expert.followers)
        self.clients = Int32(expert.clients)
        self.isPublic = expert.publicProfile
        
        let skills = NSSet(array: expert.skills.map { ManagedExpertSkill(worker: worker, skill: $0) })
        self.addToSkills(skills)
        self.user = user
    }
    
    var expertValue: Expert? {
        guard let id = self.id else {
            return nil
        }
        
        let name = self.name ?? ""
        let workType = WorkType.from(key:self.workTypeValue)
        let skills = (self.skills?.allObjects ?? []).compactMap{ $0 as? ManagedExpertSkill }.compactMap { $0.skillValue }
        return Expert(id: id,
                      name: name,
                      gender: Gender.female,
                      profileImage: self.profileImage,
                      profileVideo: self.profileVideo,
                      paypalAccount: self.paypalAccount,
                      workType: workType,
                      location: self.location,
                      followers: Int(self.followers),
                      available: self.available,
                      skills: skills,
                      clients: Int(self.clients),
                      publicProfile: self.isPublic)
    }
    
    @objc(addSkillsObject:)
    @NSManaged public func addToSkills(_ value: ManagedExpertSkill)
    
    @objc(removeSkillsObject:)
    @NSManaged public func removeFromSkills(_ value: ManagedExpertSkill)
    
    @objc(addSkills:)
    @NSManaged public func addToSkills(_ values: NSSet)
    
    @objc(removeSkills:)
    @NSManaged public func removeFromSkills(_ values: NSSet)

}
