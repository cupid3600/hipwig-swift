//
//  ManagedUser+CoreDataClass.swift
//  
//
//  Created by Vladyslav Shepitko on 5/23/19.
//
//

import Foundation
import CoreData

@objc(ManagedUser)
public class ManagedUser: NSManagedObject {
    
    @NSManaged public var availableTime: Double
    @NSManaged public var blocked: Bool
    @NSManaged public var id: String?
    @NSManaged public var isAvailable: Bool
    @NSManaged public var isSubscribed: Bool
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var profileImage: String?
    @NSManaged public var roleValue: Int32
    @NSManaged public var subscribedTo: String?
    @NSManaged public var wasBlocked: Bool
    @NSManaged public var expert: ManagedExpert?
    @NSManaged public var reviews: NSSet?
    
    convenience init(worker: NSManagedObjectContext, user: User) {
        self.init(context: worker)
        self.id = user.id
        self.name = user.name
        self.profileImage = user.profileImage
        self.roleValue = user.role.key
        self.blocked = user.youBlocked
        self.wasBlocked = user.youWasBlocked
        self.availableTime = user.availableTime
        self.isSubscribed = user.isAvailable
        self.subscribedTo = user.subscribedTo
        self.isAvailable = user.isAvailable
        
        let reviewsToSave = NSSet(array: user.reviews.map{ ManagedReviewComment(worker: worker, comment: $0, user: self) })
        self.addToReviews(reviewsToSave)
        if let expert = user.expert {
            let expertToSave = ManagedExpert(worker: worker, expert: expert, user: self)
            self.expert = expertToSave
            
            worker.insert(expertToSave)
        }
    }
    
    var userValue: User? {
        guard let id = self.id else {
            return nil
        }
        
        let name = self.name ?? ""
        let profileImage = self.profileImage ?? ""
        let email = self.email ?? ""
        let role = Role.from(key: self.roleValue)
        
        let expert = self.expert?.expertValue
        let reviews = (self.reviews?.allObjects ?? []).compactMap{ $0 as? ManagedReviewComment }.compactMap{ $0.reviewValue }
        
        return User(id: id,
                    name: name,
                    profileImage: profileImage,
                    email: email,
                    role: role,
                    youBlocked: self.blocked,
                    youWasBlocked: self.wasBlocked,
                    expert: expert,
                    availableTime: self.availableTime,
                    subscribed: self.isSubscribed,
                    subscribedTo: self.subscribedTo,
                    reviews: reviews)
    }
    
    @objc(addReviewsObject:)
    @NSManaged public func addToReviews(_ value: ManagedReviewComment)
    
    @objc(removeReviewsObject:)
    @NSManaged public func removeFromReviews(_ value: ManagedReviewComment)
    
    @objc(addReviews:)
    @NSManaged public func addToReviews(_ values: NSSet)
    
    @objc(removeReviews:)
    @NSManaged public func removeFromReviews(_ values: NSSet)
}
