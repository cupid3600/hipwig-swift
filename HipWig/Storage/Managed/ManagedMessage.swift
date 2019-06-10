//
//  ManagedMessage+CoreDataClass.swift
//  
//
//  Created by Vladyslav Shepitko on 5/23/19.
//
//

import Foundation
import CoreData

@objc(ManagedMessage)
public class ManagedMessage: NSManagedObject {
    
    @NSManaged public var id: String?
    @NSManaged public var dialogId: String?
    @NSManaged public var sender: String?
    @NSManaged public var createDate: NSDate?
    @NSManaged public var type: Int32
    @NSManaged public var systemMessageValue: String?
    @NSManaged public var message: String?
    @NSManaged public var dialog: ManagedDialog?
    
    convenience init(worker: NSManagedObjectContext, message: ChatMessage, dialog: ManagedDialog?) {
        self.init(context: worker)
        
        self.id = message.id
        self.dialogId = message.chatId
        self.sender = message.senderId
        self.createDate = message.createdAt as NSDate
        self.type = Int32(message.type.type)
        self.systemMessageValue = message.type.value
        self.message = message.message
        self.dialog = dialog
    }
    
    var messageValue: ChatMessage? {
        guard
            let id = self.id,
            let dialogId = self.dialogId,
            let sender = self.sender,
            let createDate = self.createDate,
            let text = self.message else {
                
            return nil
        }
        
        var messageType: MessageType?
        if self.type == 0 {
            messageType = .message
        } else if self.type == 1 {
            if let systemMessageValue = self.systemMessageValue {
                if let systemMessageType = SystemMessageType(rawValue: systemMessageValue) {
                    messageType = MessageType.system(systemMessageType)
                }
            }
        }
        
        if let messageType = messageType {
            let date = createDate as Date
            return ChatMessage(id: id, chatId: dialogId, message: text, senderId: sender, createdAt: date, type: messageType)
        } else {
            return nil
        }
    }
}
