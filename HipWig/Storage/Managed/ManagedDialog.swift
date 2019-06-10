//
//  ManagedDialog+CoreDataClass.swift
//  
//
//  Created by Vladyslav Shepitko on 5/23/19.
//
//

import Foundation
import CoreData

@objc(ManagedDialog)
public class ManagedDialog: NSManagedObject {

    @NSManaged public var id: String?
    @NSManaged public var unreadMesageCount: Int32
    @NSManaged public var lastMessage: ManagedMessage?
    @NSManaged public var messages: NSSet?
    @NSManaged public var me: ManagedUser?
    @NSManaged public var opponent: ManagedUser?
    
    convenience init(worker: NSManagedObjectContext, dialog: Conversation) {
        self.init(context: worker)
        
        self.id = dialog.id
        self.unreadMesageCount = Int32(dialog.unreadCount)
        
        if let message = dialog.lastMessage {
            let messageToSave = ManagedMessage(worker: worker, message: message, dialog: self)
            self.lastMessage = messageToSave
            
            self.addToMessages(messageToSave)
        }
    }
    
    func update(with dialog: Conversation, worker: NSManagedObjectContext, me: ManagedUser?, opponent: ManagedUser?) {
        self.id = dialog.id
        self.unreadMesageCount = Int32(dialog.unreadCount)
        self.me = me
        self.opponent = opponent
        
        if let message = dialog.lastMessage {
            let messageToSave = ManagedMessage(worker: worker, message: message, dialog: self)
            self.lastMessage = messageToSave
            
            self.addToMessages(messageToSave)
        }        
    }
    
    var dialogValue: Conversation? {
        guard
            let id = self.id,
            let me = self.me?.userValue,
            let opponent = self.opponent?.userValue else {
            return nil
        }
        
        let lastMessage = self.lastMessage?.messageValue
        let unreadCount = Int(self.unreadMesageCount)
        
        return Conversation(id: id,
                            users: [me, opponent],
                            lastMessage: lastMessage,
                            unreadCount: unreadCount,
                            opponent: opponent,
                            me: me)
    }

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: ManagedMessage)
    
    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: ManagedMessage)
    
    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)
    
    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
}
