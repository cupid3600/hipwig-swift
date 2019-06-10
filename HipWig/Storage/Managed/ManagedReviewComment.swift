//
//  ManagedReviewComment+CoreDataClass.swift
//  
//
//  Created by Vladyslav Shepitko on 5/23/19.
//
//

import Foundation
import CoreData

@objc(ManagedReviewComment)
public class ManagedReviewComment: NSManagedObject {
    
    @NSManaged public var text: String?
    @NSManaged public var user: ManagedUser?
    
    convenience init(worker: NSManagedObjectContext, comment: ReviewComment, user: ManagedUser?) {
        self.init(context: worker)
        self.text = comment.message
        self.user = user
    }
    
    var reviewValue: ReviewComment? {
        if let text = self.text {
            return ReviewComment(message: text)
        } else {
            return nil
        }
    }
}
