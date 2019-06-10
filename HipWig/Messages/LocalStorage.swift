//
//  LocalStorage.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/23/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import CoreData

protocol LocalStorage: class {
    
    func add(user: User, completion: @escaping ErrorHandler)
    func remove(user: String, completion: @escaping ErrorHandler)
    func has(user: User, completion: @escaping ObjectHandler<Bool>)
    func assign(user: User, me: Bool, to dialog: Conversation, completion: @escaping ErrorHandler)
    
    func fetchDialogs(_ completion: @escaping ObjectHandler<[Conversation]>)
    func fetchDialog(dialog: String, completion: @escaping ObjectHandler<Conversation?>)
    func add(dialog: Conversation, completion: @escaping ErrorHandler)
    func add(dialogs: [Conversation], completion: @escaping ErrorHandler)
    func update(with dialogs: [Conversation], completion: @escaping ErrorHandler)
    func has(dialog: String, completion: @escaping ObjectHandler<Bool>)
    func remove(dialog: String, completion: @escaping ErrorHandler)
    func remove(dialogsIds: [String], completion: @escaping ErrorHandler)
    func removeAllDialogs(completion: @escaping ErrorHandler)
    
    func fetchMessages(opponent: String, _ completion: @escaping ObjectHandler<[ChatMessage]>)
    func add(message: ChatMessage, dialog: String, completion: @escaping ErrorHandler)
    func add(messages: [ChatMessage], dialog: String, completion: @escaping ErrorHandler)
    func remove(messagesIds: [String], completion: @escaping ErrorHandler)
    
    func cleanStorage()
}

enum LocalStorageError: Error {
    case entityNotFound
}

class LocalStorageImplementation: LocalStorage {
    
    static let `default`: LocalStorageImplementation = LocalStorageImplementation()
    
    private let persistantContainer: NSPersistentContainer
    private let queue = DispatchQueue(label: "com.hipwig.com.responseQueue")
    private let databaseName = "HipWig"
    
    private init() {
        self.persistantContainer = NSPersistentContainer(name: self.databaseName)
        self.persistantContainer.loadPersistentStores { some, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            } else {
                print("data loaded succesfully")
            }
        }
    }
    
    //MARK: - Users -
    func add(user: User, completion: @escaping ErrorHandler) {
        self.persistantContainer.performBackgroundTask { worker in
            self.queue.async {
                let userToSave = ManagedUser(worker: worker, user: user)
                worker.insert(userToSave)
                
                self.save(worker) { error in
                    completion(error)
                }
            }
        }
    }
    
    func has(user: User, completion: @escaping ObjectHandler<Bool>) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedUser.identifier)
        fetchRequest.predicate = NSPredicate(format: "id = %@", user.id)
        
        self.persistantContainer.performBackgroundTask { worker in
            self.queue.async {
                self.fetchRequest(worker, fetchRequest: fetchRequest, type: ManagedUser.self) { users in
                    completion(!users.isEmpty)
                }
            }
        }
    }
    
    private func managedUser(user: User, worker: NSManagedObjectContext, completion: @escaping ObjectHandler<ManagedUser?>) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedUser.identifier)
        fetchRequest.predicate = NSPredicate(format: "id = %@", user.id)
        
        self.fetchRequest(worker, fetchRequest: fetchRequest, type: ManagedUser.self) { users in
            let result = users.first
            
            completion(result)
        }
    }
    
    private func managedDialog(dialog: Conversation, worker: NSManagedObjectContext, completion: @escaping ObjectHandler<ManagedDialog?>) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDialog.identifier)
        fetchRequest.predicate = NSPredicate(format: "id = %@", dialog.id)
        
        self.fetchRequest(worker, fetchRequest: fetchRequest, type: ManagedDialog.self) { dialogs in
            let result = dialogs.first
            
            completion(result)
        }
    }
    
    func remove(user id: String, completion: @escaping ErrorHandler) {
        
    }
    
    func assign(user: User, me: Bool, to dialog: Conversation, completion: @escaping ErrorHandler) {
        self.persistantContainer.performBackgroundTask { worker in
            self.queue.async {
                self.managedDialog(dialog: dialog, worker: worker) { dialogToUpdate in
                    self.managedUser(user: user, worker: worker) { managedUser in
                        if me {
                            dialogToUpdate?.me = managedUser
                        } else {
                            dialogToUpdate?.opponent = managedUser
                        }
                        
                        self.save(worker) { error in
                            completion(error)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Dialogs -
    func update(with dialog: Conversation, completion: @escaping ErrorHandler) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDialog.identifier)
        fetchRequest.predicate = NSPredicate(format: "id = %@", dialog.id)
        
        self.persistantContainer.performBackgroundTask { worker in
            self.queue.async {
                self.fetchRequest(worker, fetchRequest: fetchRequest, type: ManagedDialog.self) { result in
                    self.managedUser(user: dialog.me, worker: worker) { me in
                        self.managedUser(user: dialog.opponent, worker: worker) { opponent in
                            
                            result.first?.update(with: dialog, worker: worker, me: me, opponent: opponent)
                            
                            self.save(worker) { error in
                                completion(error)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func update(with dialogs: [Conversation], completion: @escaping ErrorHandler) {
        let group = DispatchGroup()
        var resultError: Error?
        
        for dialog in dialogs {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.update(with: dialog) { error in
                    if resultError == nil {
                        resultError = error
                    }
                    
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(resultError)
        }
    }
    
    func fetchDialogs(_ completion: @escaping ObjectHandler<[Conversation]>) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDialog.identifier)
        
        self.persistantContainer.performBackgroundTask { worker in
            self.queue.async {
                self.fetchRequest(worker, fetchRequest: fetchRequest, type: ManagedDialog.self) { result in
                    let dialogs = result.compactMap{ $0.dialogValue }
                    completion(dialogs)
                }
            }
        }
    }
    
    func has(dialog id: String, completion: @escaping ObjectHandler<Bool>) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDialog.identifier)
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        
        self.persistantContainer.performBackgroundTask { worker in
            self.queue.async {
                self.fetchRequest(worker, fetchRequest: fetchRequest, type: ManagedDialog.self) { result in
                    let hasDialog = !result.isEmpty
                    completion(hasDialog)
                }
            }
        }
    }
    
    func fetchDialog(dialog id: String, completion: @escaping ObjectHandler<Conversation?>) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDialog.identifier)
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        
        self.persistantContainer.performBackgroundTask { worker in
            self.queue.async {
                self.fetchRequest(worker, fetchRequest: fetchRequest, type: ManagedDialog.self) { result in
                    let dialog = result.first?.dialogValue
                    completion(dialog)
                }
            }
        }
    }
    
    func add(dialog: Conversation, completion: @escaping ErrorHandler) {
        self.add(dialogs: [dialog], completion: completion)
    }
    
    func add(dialogs: [Conversation], completion: @escaping ErrorHandler) {
        self.persistantContainer.performBackgroundTask { worker in
            worker.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            self.queue.sync {
                dialogs.forEach { dialog in
                    let dialogToSave = ManagedDialog(worker: worker, dialog: dialog)
                    worker.insert(dialogToSave)
                }

                self.save(worker) { error in
                    completion(error)
                }
            }
        }
    }
    
    func remove(dialogsIds: [String], completion: @escaping ErrorHandler) {
        let group = DispatchGroup()
        var resultError: Error?
        
        for dialog in dialogsIds {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.remove(dialog: dialog){ error in
                    if resultError == nil {
                        resultError = error
                    }

                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(resultError)
        }
    }
    
    func remove(dialog: String, completion: @escaping ErrorHandler) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDialog.identifier)
        fetchRequest.predicate = NSPredicate(format: "id = %@", dialog)
        
        self.persistantContainer.performBackgroundTask { worker in
            self.removeEntity(worker, fetchRequest: fetchRequest, type: ManagedDialog.self) { error in
                completion(error)
            }
        }
    }
    
    func removeAllDialogs(completion: @escaping ErrorHandler) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDialog.identifier)
        
        self.persistantContainer.performBackgroundTask { worker in
            self.removeEntity(worker, fetchRequest: fetchRequest, type: ManagedDialog.self) { error in
                completion(error)
            }
        } 
    }
    
    //MARK: - Messages -
    func fetchMessages(opponent: String, _ completion: @escaping ObjectHandler<[ChatMessage]>) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDialog.identifier)
        fetchRequest.predicate = NSPredicate(format: "opponent.id = %@", opponent)
        
        self.persistantContainer.performBackgroundTask { worker in
            self.queue.async {
                self.fetchRequest(worker, fetchRequest: fetchRequest, type: ManagedDialog.self) { result in
                    let savedMassages = (result.first?.messages?.allObjects ?? []).compactMap{ $0 as? ManagedMessage }
                    
                    let messagesToReturn = savedMassages.compactMap{ $0.messageValue }
                    completion(messagesToReturn)
                }
            }
        }
    }
    
    func add(message: ChatMessage, dialog: String, completion: @escaping ErrorHandler) {
        self.add(messages: [message], dialog: dialog, completion: completion)
    }
    
    func add(messages: [ChatMessage], dialog: String, completion: @escaping ErrorHandler) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDialog.identifier)
        fetchRequest.predicate = NSPredicate(format: "id = %@", dialog)
        
        self.persistantContainer.performBackgroundTask { worker in
            worker.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            self.queue.async {
                self.fetchRequest(worker, fetchRequest: fetchRequest, type: ManagedDialog.self) { result in
                    
                    let dialog = result.first
                    let mesagesToSave = messages.map {
                        return ManagedMessage(worker: worker, message: $0, dialog: dialog)
                    }
                    
                    let set = NSSet(array: mesagesToSave)
                    dialog?.addToMessages(set)
                    
                    self.save(worker) { error in
                        completion(error)
                    }
                }
            } 
        }
    }
    
    func remove(messagesIds: [String], completion: @escaping ErrorHandler) {
//        persistantContainer.performBackgroundTask { worker in
//            self.queue.sync {
//
//                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedMessage.identifier)
//                fetchRequest.predicate
//                self.removeEntity(worker, fetchRequest: fetchReques, type: ManagedCard.self) { error in
//                    //          print("Finished delete cards")
//                    completionHandler(error)
//                }
//            }
//        }
    }
    
    func cleanStorage() {
        self.removeAllDialogs { _ in
            
        }
    }
    
    //MARK: - Private -
    private func save(_ context: NSManagedObjectContext, completionHandler: (NSError?) -> Void) {
        var error: NSError? = nil
        
        do {
            try context.save()
        } catch let saveError as NSError {
            error = saveError
        }
        
        completionHandler(error)
    }
    
    private func fetchRequest<T>(_ worker: NSManagedObjectContext,
                                 fetchRequest: NSFetchRequest<NSFetchRequestResult>,
                                 type: T.Type,
                                 completionHandler: @escaping ([T]) -> Void) where T : NSManagedObject {
        
        do {
            let results = try worker.fetch(fetchRequest) as? [T] ?? []
            completionHandler(results)
        } catch let error {
            print("Finished fetch for entities of type \(type.identifier) with error: \(error)")
            completionHandler([])
        }
    }
    
    private func removeEntity<T>(_ worker: NSManagedObjectContext,
                                 fetchRequest: NSFetchRequest<NSFetchRequestResult>,
                                 type: T.Type,
                                 completionHandler: @escaping (Error?) -> Void) where T : NSManagedObject {
        
        let mainContext = persistantContainer.viewContext
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        var error: Error? = nil
        
        do {
            let result = try worker.execute(deleteRequest) as? NSBatchDeleteResult
            
            let objectIDs = result?.result as? [NSManagedObjectID] ?? []
            let changes = [NSDeletedObjectsKey: objectIDs]
            
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [mainContext])
            
        } catch let saveError {
            error = saveError
        }
        
        completionHandler(error)
    }
}
