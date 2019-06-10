//
//  SocketManager.swift
//  HipWig
//
//  Created by Alexey on 1/23/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import SocketIO
import MulticastDelegateSwift

protocol SocketWrapperDelegate: class {
    
    func onConnect()
    func onDisconnect()
    
    func soket(_ socket: SocketWrapper, didShangeStatus status: WrapperStatus)
    func soket(_ socket: SocketWrapper, didJoinToChat id: String?)
    func soket(_ socket: SocketWrapper, didLeaveChat id: String?)
    func soket(_ socket: SocketWrapper, didReceiveMessage message: ChatMessage)
}

enum WrapperStatus : Int {
    case notConnected
    case disconnected
    case connecting
    case connected

    public var description: String {
        switch self {
        case .connected:    return "connected"
        case .connecting:   return "connecting"
        case .disconnected: return "disconnected"
        case .notConnected: return "notConnected"
        }
    }
}

class SocketWrapper {
    
    static public var wrapper = SocketWrapper()
    
    let delegate = MulticastDelegate<SocketWrapperDelegate>()
    
    private var manager = SocketManager(socketURL: environment.socketURL, config: [.log(false), .compress])
    private let chatPresenseService: ChatPresenceService = ChatPresenceServiceImplementation.default
    
    private (set) var isJoinedToChat = false

    private lazy var client: SocketIOClient = { self.manager.defaultSocket }()
    
    func add(delegate: SocketWrapperDelegate) {
        if !self.delegate.containsDelegate(delegate) {
            self.delegate += delegate
        }
    }
    
    func remove(delegate: SocketWrapperDelegate) {
        self.delegate -= delegate
    }
    
    private init() {

        self.client.on(clientEvent: .connect) { _, _ in
            self.isJoinedToChat = false
            
            let events = self.eventList.filter{ $0.event == Event.disconnect }
            events.forEach{ event in
                self.eventList.removeAll(where: { $0 == event })
                event.action()
            }
            
            self.delegate |> { delegate in
                delegate.onConnect()
            }
        }
        
        self.client.on(clientEvent: .disconnect) { _, _ in
            self.isJoinedToChat = false
            
            let events = self.eventList.filter{ $0.event == Event.disconnect }
            events.forEach{ event in
                self.eventList.removeAll(where: { $0 == event })
                event.action()
            }
            
            self.delegate |> { delegate in
                delegate.onDisconnect()
            }
        }

        self.client.on("sendMessage") { data, _ in
            self.delegate |> { [weak self] delegate in
                guard let `self` = self else { return }
                
                if let message = self.parseIncomingMessage(data: data) {
                    let event = Event.send(message: message.message, dialog: message.chatId)
                    
                    let events = self.eventList.filter { $0.event == event }
                    events.forEach{ event in
                        self.eventList.removeAll(where: { $0 == event })
                        event.action()
                    }
                    
                    delegate.soket(self, didReceiveMessage: message)
                }
            }
        }

        self.client.on("join") { [weak self] content, _ in
            
            guard let `self` = self else { return }
            self.isJoinedToChat = true
            
            if let id = self.parseChatIdentifier(from: content) {
                let events = self.eventList.filter{ $0.event == Event.join(chat: id) }
                
                events.forEach { event in
                    self.eventList.removeAll(where: { $0 == event })
                    event.action()
                }
                
                self.delegate |> { delegate in
                    delegate.soket(self, didJoinToChat: id)
                }
            }
        }

        self.client.on("leave") { [weak self] content, _ in
            guard let `self` = self else { return }
            self.isJoinedToChat = false
            
            if let id = self.parseChatIdentifier(from: content) {
                let events = self.eventList.filter{ $0.event == Event.leave(chat: id) }
                
                events.forEach{ event in
                    self.eventList.removeAll(where: { $0 == event })
                    event.action()
                }

                self.delegate |> { delegate in
                    delegate.soket(self, didLeaveChat: id)
                }
            }
        }

        self.client.on(clientEvent: .statusChange) { [weak self] content, _ in
            guard let `self` = self else { return }
            
            if let socketStatus = content.first as? SocketIOStatus {
                if let status = WrapperStatus(rawValue: socketStatus.rawValue) {
                    self.delegate |> { delegate in
                        delegate.soket(self, didShangeStatus: status)
                    }
                }
            }
        }
        
        self.client.onAny {
            if $0.event == "error" {
                print("SOKET ERROR event: \($0.event), with items: \(String(describing: $0.items))")
            } else {
                print("SOKET event: \($0.event), with items: \(String(describing: $0.items))")
            }
        }
        
        NotificationCenter.addWillEnterForegroundObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.client.connect()
        }
        
        NotificationCenter.addApplicationDidEnterBackgroundObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.client.disconnect()
        }
    }
    
    var status: SocketIOStatus {
        return self.client.status
    }
    
    func waitWhenConnected(_ completion: @escaping () -> Void = {}) {
        let event = EventWrapper(event: .connect, action: completion)
        self.eventList.append(event)
    }
    
    func waitWhenJoined(dialog: String, completion: @escaping () -> Void = {}) {
        let event = EventWrapper(event: .join(chat: dialog), action: completion)
        self.eventList.append(event)
    }

    public func connect(completion: @escaping () -> Void = {}) {
        let event = EventWrapper(event: .connect, action: completion)
        self.eventList.append(event)
        
        self.client.connect()
    }

    public func disconnect(completion: @escaping () -> Void = {}) {
        let event = EventWrapper(event: .disconnect, action: completion)
        self.eventList.append(event)

        self.client.disconnect()
    }

    private enum Event : Equatable {
        case connect
        case disconnect
        case join(chat: String)
        case leave(chat: String)
        case send(message: String, dialog: String)

        static func == (lhs: Event, rhs: Event) -> Bool {
            switch (lhs, rhs) {
            case (.connect, .connect):
                return true
            case (.disconnect, .disconnect):
                return true
            case (.join(let chat1), .join(let chat2)):
                return chat1 == chat2
            case (.leave(let chat1), .leave(let chat2)):
                return chat1 == chat2
            case (.send(let message1, let dialog1), .send(let message2, let dialog2)):
                return message1 == message2 && dialog1 == dialog2
            default:
                return false
            }
        }
    }
    
    private struct EventWrapper: Equatable {
        
        let event: Event
        let action: () -> Void
        let id: String
        
        init(event: Event, action: @escaping () -> Void) {
            self.event = event
            self.action = action
            self.id = UUID().uuidString
        }
    
        static func == (lhs: EventWrapper, rhs: EventWrapper) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    private var eventList: [EventWrapper] = []
    
    public func join(chatID id: String, completion: @escaping () -> Void = {}) {
        let params = ["chatId" : id]
        
        let event = EventWrapper(event: .join(chat: id), action: completion)
        self.eventList.append(event)
        
        if let data = self.convertToJSON(data: params) {
            self.chatPresenseService.set(chatId: id)
            
            self.client.emit("join", data)
        }
    }

    public func leave(chatID id: String, completion: @escaping () -> Void = {}) {
        let params = ["chatId" : id]
        
        let event = EventWrapper(event: .leave(chat: id), action: completion)
        self.eventList.append(event)
        
        if let data = self.convertToJSON(data: params) {
            self.chatPresenseService.set(chatId: nil)
            self.client.emit("leave", data)
        }
    }

    public func sendMessage(chatID dialog: String, receiver: String, sender: String, message: String, completion: @escaping () -> Void = {}) {
        var params: [String : Any] = [:]
        
        params["partnerId"] = receiver
        params["chatId"] = dialog
        params["userId"] = sender
        params["message"] = message
        
        let event = EventWrapper(event: .send(message: message, dialog: dialog), action: completion)
        self.eventList.append(event)
        
        if let data = self.convertToJSON(data: params) {
            self.client.emit("sendMessage", data)
        }
    }

    public func readMessage(chatID: String, myID: String, lastMessageID: String) {
        var params: [String : Any] = [:]
        
        params["messageId"] = lastMessageID
        params["chatId"] = chatID
        params["userId"] = myID
        
        guard let data = self.convertToJSON(data: params) else {
            return
        }
        
        self.client.emit("lastMessage", data)
    }

    //MARK: - Private -
    private func convertToJSON(data: [String : Any]) -> String? {
        let jsonString: String?
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            jsonString = String(data: jsonData, encoding: .utf8)
        }
        catch {
            print("[socket]: convert emit data error: \(error).")
            jsonString = nil
        }
        
        return jsonString
    }

    private func parseIncomingMessage(data: [Any]) -> ChatMessage? {
        var message: ChatMessage?
        
        if let castedData = data.first as? [String: Any] {
            do {
                let raw = try JSONSerialization.data(withJSONObject: castedData, options: .prettyPrinted)
                message = try JSONDecoder().decode(ChatMessage.self, from: raw)
            } catch {
                print("[socket]: parsing incoming message error: \(error).")
            }
        }
        
        return message
    }
    
    private func parseChatIdentifier(from data: Any) -> String? {
        if let items = data as? [[String: Any]] {
            if let data = items.first {
                return data["chatId"] as? String
            }
        }
        
        return nil
    }
}
