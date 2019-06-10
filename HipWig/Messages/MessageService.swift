//
//  ChatService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/23/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import MulticastDelegateSwift

typealias FetchMessageResult = (messages: [ChatMessage], pagination: Pagination)
typealias FetchDialogResult = (dialogs: [Conversation], pagination: Pagination)

protocol MessageService: class {
    
    func fetchMessages(_ pagination: Pagination, date: Date, completion: @escaping ValueHandler<FetchMessageResult>)
    func fetchMessages(_ pagination: Pagination, opponent: String, completion: @escaping ValueHandler<FetchMessageResult>)
    func fetchMessages(_ pagination: Pagination,
                       opponent: String,
                       localStorageCompletion: @escaping ObjectHandler<[ChatMessage]>,
                       remoteStorageCompletion: @escaping ObjectHandler<FetchMessageResult>,
                       failure: @escaping ErrorHandler)
    
    func fetchDialogs(_ pagination: Pagination, completion: @escaping ValueHandler<FetchDialogResult>)
    func delete(dialog id: String, completion: @escaping ErrorHandler)
    
    func createDialog(receiver opponet: String, completion: @escaping ErrorHandler)
    func leaveDialog(receiver opponet: String, completion: @escaping ErrorHandler)
    
    func send(message: String, to receiver: String, completion: @escaping ErrorHandler)
    func syncronize()
    
    func add(delegate: MessageServiceDelegate)
    func remove(delegate: MessageServiceDelegate)
    
    func hasChat(_ id: String, completion: @escaping (Bool) -> Void)
    
    func clean()
}

protocol MessageServiceDelegate: class {
    func service(_ service: MessageService, didSendMessage message: ChatMessage)
    func service(_ service: MessageService, didReceiveMessage message: ChatMessage)
    
    func service(_ service: MessageService, didUpdateDialog dialog: Conversation)
}

enum MessageServiceError: Error {
    case dialogNotFound
}

class MessageServiceImplementation: NSObject, MessageService {
    
    public static let `default`: MessageServiceImplementation = MessageServiceImplementation()
    public let delegate = MulticastDelegate<MessageServiceDelegate>()
    
    private let socketService: SocketWrapper = SocketWrapper.wrapper
    private let localStorage: LocalStorage = LocalStorageImplementation.default
    private let api: RequestsManager = RequestsManager.manager
    private let account: AccountManager = AccountManager.manager
    
    private var sender: String {
        if let sender = self.account.myUserID {
            return sender
        } else {
            return ""
        }
    }
    
    private override init() {
        super.init()
        
//        self.socketService.add(delegate: self)
//
//        NotificationCenter.addRecieveNewMessageObserver { [weak self] dialog, _ in
//            guard let `self` = self else {
//                return
//            }
//
//            if let info = self.dialogInfo(for: dialog.opponent.id) {
//
//            } else {
//
//            }
        
//            self.addOrUpdateDialog(dialog) { error in
//                if let error = error {
//                    logger.log(error)
//                } else {
//                    self.localStorage.fetchDialog(dialog: dialog.id) { dialog in
//                        if let dialog = dialog {
//                            self.delegate |> { delegate in
//                                delegate.service(self, didUpdateDialog: dialog)
//                            }
//
//                            if let message = dialog.lastMessage {
//
//                                let sendMessage = message.senderId == self.sender
//
//                                self.delegate |> { delegate in
//                                    if sendMessage {
//                                        delegate.service(self, didSendMessage: message)
//                                    } else {
//                                        delegate.service(self, didReceiveMessage: message)
//                                    }
//                                }
//                            } else {
//                                //Do Nothing
//                            }
//                        }
//                    }
//                }
//            }
//        }
    }
    
    func add(delegate: MessageServiceDelegate) {
        self.delegate += delegate
    }
    
    func remove(delegate: MessageServiceDelegate) {
        self.delegate -= delegate
    }
    
    func clean() {
//        self.dialogInfoList.forEach { info in
//            self.socketService.leave(chatID: info.dialog) {
//
//            }
//        }
        self.dialogInfoList.removeAll()
        self.localStorage.cleanStorage()
    }
    
    func syncronize() {
//        let pagination = Pagination.default(with: Int.max)
//        self.api.getUserChats(pagination: pagination) { result in
//            switch result {
//            case .success(let fetchedDialogs):
//                self.localStorage.fetchDialogs { savedDialogs in
//                    let dialogsToAdd = fetchedDialogs.rows.filter{ !savedDialogs.contains($0) }
//                    let dialogsToDelete = savedDialogs.filter{ !fetchedDialogs.rows.contains($0) }
//                    let dialogsToUpdate = fetchedDialogs.rows.filter{ !dialogsToAdd.contains($0) && !dialogsToDelete.contains($0) }
//
//                    let deleteDialogsids = dialogsToDelete.map{ $0.id }
//
//                    self.localStorage.remove(dialogsIds: deleteDialogsids) { removeDialogsError in
//                        if let error = removeDialogsError {
//                            logger.log(error)
//                        } else {
//                            self.localStorage.add(dialogs: dialogsToAdd) { saveDialogsError in
//                                if let error = saveDialogsError {
//                                    logger.log(error)
//                                } else {
//                                    self.localStorage.update(with: dialogsToUpdate) { updateDialogsError in
//                                        if let error = updateDialogsError {
//                                            logger.log(error)
//                                        } else {
//                                            //done
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            case .failure(let error):
//               logger.log(error)
//            }
//        }
    }
    
    private var messagesToSend: [ChatMessage] = []
    
    //MARK: - Messages -
    
    func hasChat(_ id: String, completion: @escaping (Bool) -> Void) {
        let pagination = Pagination.default(with: Int.max)
        self.api.getUserChats(pagination: pagination) { result in
            var isConversationExists: Bool = false
            
            switch result {
            case .success(let response):
                let conversations = response.rows.filter{ $0.lastMessage != nil }
                
                isConversationExists = conversations.contains(where: { $0.id == id })
            case .failure(let error):
                logger.log(error)
            }
            
            completion(isConversationExists)
        }
    }
    
    func fetchMessages(_ pagination: Pagination,
                       opponent: String,
                       localStorageCompletion: @escaping ObjectHandler<[ChatMessage]>,
                       remoteStorageCompletion: @escaping ObjectHandler<FetchMessageResult>,
                       failure: @escaping ErrorHandler) {
        self.localStorage.fetchMessages(opponent: opponent) { messages in
            localStorageCompletion(messages)
            
            if messages.isEmpty {
                
            } else {
                
            }
        }
        
    }
    
    func fetchMessages(_ pagination: Pagination, date: Date, completion: @escaping ValueHandler<FetchMessageResult>) {

    }
    
    func fetchMessages(_ pagination: Pagination, opponent: String, completion: @escaping ValueHandler<FetchMessageResult>) {
        self.localStorage.fetchMessages(opponent: opponent) { messages in
            if messages.isEmpty {
                //load messages
            } else {
                
            }
        }
        
//        if let dialogInfo = self.dialogInfo(for: opponent) {
//
//        } else {
//            //Wait when connected
//        }
    }
    
    func send(message text: String, to opponent: String, completion: @escaping ErrorHandler) {
        
//        let id = UUID().uuidString
//        let date = Date()
//
//        let message = ChatMessage(id: id, chatId: dialogId, message: text, senderId: sender, createdAt: date, type: .message)
//        self.undeliveredMessages.append(message)
//
//        self.localStorage.add(message: message) { error in
//            if let error = error {
//                logger.log(error)
//            } else {
//                //send message
//            }
//        }
//        self.socketService.sendMessage(chatID: <#T##String#>, receiver: <#T##String#>, sender: <#T##String#>, message: <#T##String#>, completion: <#T##() -> Void#>)
//        let isDialogCreated = text.count > 0
//        if isDialogCreated {
//
//        } else {
//            self.createDialog(receiver) { dialog in
////                let state = Some(dialog: dialog, status: .creaded)
////                self.dialogStates.insert(state)
//
////                //save dialog to temp storage
////                self.send(message: text, to: receiver) { error in
////
////                }
//            }
//        }
        
        if let info = self.dialogInfo(for: opponent) {
            switch info.status {
            case .joined:
                self.socketService.sendMessage(chatID: info.dialog, receiver: opponent, sender: self.sender, message: text) {
                    completion(nil)
                }
            default:
                self.socketService.waitWhenJoined(dialog: info.dialog) {
                    self.socketService.sendMessage(chatID: info.dialog, receiver: opponent, sender: self.sender, message: text) {
                        completion(nil)
                    }
                }
            }
        } else {
            print("dialog with \(opponent) isn't created")
            completion(nil)
        }
        
    }
    
    private var dialogInfoList: Set<DialogInfo> = []
    
    private enum DialogConnectionState {
        case connecting
        case joining
        case joined
        case creaded
    }
    
    private struct DialogInfo: Hashable, Equatable {
        var dialog: String
        var opponent: String
        var status: DialogConnectionState
        var listeners: Int
        let id: String
        
        init(dialog: String, opponent: String, status: DialogConnectionState) {
            self.dialog = dialog
            self.status = status
            self.opponent = opponent
            self.id = UUID().uuidString
            self.listeners = 1
        }
        
        mutating func addListener() {
            self.listeners += 1
        }
        
        mutating func removeListener() {
            self.listeners += 1
        }
        
        var hasListeners: Bool {
            return self.listeners > 1
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(dialog)
            hasher.combine(id)
        }
    }
    
    private func dialogStatus(for opponent: String) -> DialogConnectionState? {
        return self.dialogInfoList.first(where: { $0.opponent == opponent })?.status
    }
    
    private func dialogInfo(for opponent: String) -> DialogInfo? {
        return self.dialogInfoList.first(where: { $0.opponent == opponent })
    }
    
    @discardableResult
    private func addListenerForDialogWith(_ opponent: String) -> Bool {
        if let index = self.dialogInfoList.firstIndex(where: { $0.opponent == opponent }) {
            var state = self.dialogInfoList[index]
            state.addListener()
            
            self.dialogInfoList.remove(at: index)
            self.dialogInfoList.insert(state)
            
            return true
        } else {
            return false
        }
    }
    
    @discardableResult
    private func removeListenerForDialogWith(_ opponent: String) -> Bool {
        if let index = self.dialogInfoList.firstIndex(where: { $0.opponent == opponent }) {
            var state = self.dialogInfoList[index]
            state.removeListener()
            
            self.dialogInfoList.remove(at: index)
            self.dialogInfoList.insert(state)
            
            return true
        } else {
            return false
        }
    }
    
    @discardableResult
    private func setDialogStatus(for opponent: String, status: DialogConnectionState) -> Bool {
        if let index = self.dialogInfoList.firstIndex(where: { $0.opponent == opponent }) {
            var state = self.dialogInfoList[index]
            state.status = status
            
            self.dialogInfoList.remove(at: index)
            self.dialogInfoList.insert(state)
            
            return true
        } else {
            return false
        }
    }
    
    private func removeDialogInfo(for opponent: String) {
        if let index = self.dialogInfoList.firstIndex(where: { $0.opponent == opponent }) {
            self.dialogInfoList.remove(at: index)
        }
    }
    
    //MARK: - Dialogs -
    func leaveDialog(receiver opponet: String, completion: @escaping ErrorHandler) {
        if let info = self.dialogInfo(for: opponet) {
            if info.hasListeners {
                self.removeListenerForDialogWith(opponet)
                completion(nil)
            } else {
                self.removeDialogInfo(for: opponet)
                self.socketService.leave(chatID: info.dialog) {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    func createDialog(receiver opponent: String, completion: @escaping ErrorHandler) {
        if let info = self.dialogInfo(for: opponent) {
            //Проверить текущие состояние сокета
            switch info.status {
            case .joined:
                
                self.addListenerForDialogWith(opponent)
                completion(nil)
            default:
                self.socketService.waitWhenJoined(dialog: info.dialog) {
                    completion(nil)
                }
            }
        } else {
            let createDialogClosure = {
                self.createDialog(opponent) { result in
                    switch result {
                    case .success(let id):
                        let state = DialogInfo(dialog: id, opponent: opponent, status: .creaded)
                        self.dialogInfoList.insert(state)
                        
                        self.joinToDialog(with: opponent, dialog: id) { error in
                            completion(error)
                        }
                    case .failure(let error):
                        self.removeDialogInfo(for: opponent)
                        completion(error)
                    }
                }
            }
            
            if reachability.isNetworkReachable {
                createDialogClosure()
            } else {
                reachability.addWhenReachable(self) {
                    if let _ = self.dialogInfo(for: opponent) {
                        createDialogClosure()
                    } else {
                        print("called leave for dialog with \(opponent)")
                    }
                }
            }
        }
    }
    
    private func joinToDialog(with opponent: String, dialog: String, completion: @escaping ErrorHandler) {
        if self.socketService.status == .notConnected || self.socketService.status == .disconnected {
            self.setDialogStatus(for: opponent, status: .connecting)
            
            self.socketService.connect {
                self.setDialogStatus(for: opponent, status: .joining)
                
                self.socketService.join(chatID: dialog) {
                    self.setDialogStatus(for: opponent, status: .joined)
                    
                    completion(nil)
                }
            }
        } else if self.socketService.status == .connecting {
            self.setDialogStatus(for: opponent, status: .connecting)
            
            self.socketService.waitWhenConnected {
                self.setDialogStatus(for: opponent, status: .joining)
                
                self.socketService.join(chatID: dialog) {
                    self.setDialogStatus(for: opponent, status: .joined)
                    
                    completion(nil)
                }
            }
        } else {
            self.setDialogStatus(for: opponent, status: .joining)
            
            self.socketService.join(chatID: dialog) {
                self.setDialogStatus(for: opponent, status: .joined)
                
                completion(nil)
            }
        }
    }
    
    func fetchDialogs(_ pagination: Pagination, completion: @escaping ValueHandler<FetchDialogResult>) {
        if reachability.isNetworkReachable {
            self.loadDialogs(pagination: pagination) { result in
                switch result {
                case .success(let result):
                    if result.rows.isEmpty {
                        self.localStorage.removeAllDialogs { error in
                            if let error = error {
                                DispatchQueue.main.async {
                                    completion(.failure(error))
                                }
                            } else {
                                let pagination = Pagination.default(with: pagination.totalCount)
                                let result = (dialogs: Array<Conversation>(), pagination: pagination)
                                
                                DispatchQueue.main.async {
                                    completion(.success(result))
                                }
                            }
                        }
                    } else {
                        let group = DispatchGroup()
                        var savedDialogs: [(dialog: Conversation, error: Error?)] = []

                        result.rows.forEach { dialog in
                            group.enter()
                            self.addOrUpdateDialog(dialog) { error in
                                if let error = error {
                                    logger.log(error)
                                }
                                
                                savedDialogs.append((dialog: dialog, error: error))

                                group.leave()
                            }
                        }

                        group.notify(queue: .main) {
                            //FIXME: add more checks for saved dialogs errors and update pagination with unsaved dialogs
                            self.localStorage.fetchDialogs{ savedDialogs in
                                let pagination = Pagination(totalCount: pagination.totalCount, limit: pagination.limit, offset: savedDialogs.count, isEmpty: false, isFetching: false)
                                let result = (dialogs: savedDialogs, pagination: pagination)
                                
                                DispatchQueue.main.async {
                                    completion(.success(result))
                                }
                            }
                        }
                    }
                case .failure(let error):
                    self.localStorage.fetchDialogs { dialogs in
                        if dialogs.isEmpty {
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        } else {
                            let pagination = Pagination(totalCount: dialogs.count, limit: dialogs.count, offset: dialogs.count, isEmpty: false, isFetching: false)
                            let result = (dialogs: dialogs, pagination: pagination)
                            
                            DispatchQueue.main.async {
                                completion(.success(result))
                            }
                        }
                    }
                }
            }
        } else {
            self.localStorage.fetchDialogs { dialogs in
                if dialogs.isEmpty {
                    let result = (dialogs: dialogs, pagination: Pagination.default)
                    
                    DispatchQueue.main.async {
                        completion(.success(result))
                    }
                } else {
                    let pagination = Pagination(totalCount: dialogs.count, limit: dialogs.count, offset: dialogs.count, isEmpty: false, isFetching: false)
                    let result = (dialogs: dialogs, pagination: pagination)
                    
                    DispatchQueue.main.async {
                        completion(.success(result))
                    }
                }
            }
        }
    }
    
    func delete(dialog id: String, completion: @escaping ErrorHandler) {
        self.api.deleteChat(chatID: id) { error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(error)
                }
            } else {
                self.localStorage.remove(dialog: id) { error in
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
        }
    }
    
    //MARK: - Private -
    private func loadDialogs(pagination: Pagination, completion: @escaping ValueHandler<ConversationsListResponse>) {
        self.api.getUserChats(pagination: pagination, completion: completion)
    }
}

//MARK: - SocketWrapperDelegate
extension MessageServiceImplementation: SocketWrapperDelegate {
    
    func onConnect() {
        
    }
    
    func onDisconnect() {
        
    }
    
    func soket(_ socket: SocketWrapper, didShangeStatus status: WrapperStatus) {
        
    }
    
    func soket(_ socket: SocketWrapper, didJoinToChat id: String?) {
        if let id = id {
            
        }
    }
    
    func soket(_ socket: SocketWrapper, didLeaveChat id: String?) {
        if let id = id {
            
        }
    }
    
    func soket(_ socket: SocketWrapper, didReceiveMessage message: ChatMessage) {
        self.addOrUpdateMessage(message) { error in
            if let error = error {
                logger.log(error)
            } else {
                let sendMessage = message.senderId == self.sender
                self.delegate |> { delegate in
                    if sendMessage {
                        delegate.service(self, didSendMessage: message)
                    } else {
                        delegate.service(self, didReceiveMessage: message)
                    }
                }
            }
        }
    }
    
    private func addOrUpdateDialog(_ dialog: Conversation, completion: @escaping ErrorHandler) {
        self.localStorage.has(dialog: dialog.id) { hasDialog in
            if hasDialog {
                self.localStorage.update(with: [dialog]) { error in
                    completion(error)
                }
            } else {
                self.localStorage.add(dialog: dialog) { error in
                    if let error = error {
                        completion(error)
                    } else {
                        self.addOrUpdateUser(user: dialog.me, for: dialog) { error in
                            if let error = error {
                                completion(error)
                            } else {
                                self.addOrUpdateUser(user: dialog.opponent, for: dialog) { error in
                                    completion(error)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func addOrUpdateUser(user: User, for dialog: Conversation, completion: @escaping ErrorHandler) {
        let isMe = dialog.me.id == user.id
        self.localStorage.has(user: user) { hasUser in
            if hasUser {
                self.localStorage.assign(user: user, me: isMe, to: dialog) { error in
                    completion(error)
                }
            } else {
                self.localStorage.add(user: user) { error in
                    if let error = error {
                        completion(error)
                    } else {
                        self.localStorage.assign(user: user, me: isMe, to: dialog) { error in
                            completion(error)
                        }
                    }
                }
            }
        }
    }
    
    private func addOrUpdateMessage(_ message: ChatMessage, completion: @escaping ErrorHandler) {
        self.localStorage.fetchDialog(dialog: message.chatId) { dialog in
            if let dialog = dialog {
                self.localStorage.add(message: message, dialog: dialog.id) { error in
                    completion(error)
                }
            } else {
                self.loadAndSaveDialog(id: message.chatId) { result in
                    switch result {
                    case .success(let dialog):
                        self.localStorage.add(message: message, dialog: dialog.id) { error in
                            completion(error)
                        }
                    case .failure(let error):
                        completion(error)
                    }
                }
            }
        }
    }
    
    private func createDialog(_ receiver: String, completion: @escaping ValueHandler<String>) {
        self.api.createChat(userID: nil, expertID: receiver) {response in
            switch response {
            case .success(let id):
                completion(.success(id))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func loadAndSaveDialog(id: String, completion: @escaping ValueHandler<Conversation>) {
        self.api.loadDialog(id: id) { result in
            switch result {
            case .success(let dialog):
                if let dialog = dialog {
                    self.localStorage.add(dialogs: [dialog]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(dialog))
                        }
                    }
                } else {
                    completion(.failure(MessageServiceError.dialogNotFound))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

