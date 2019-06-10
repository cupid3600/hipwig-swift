//
//  ChatMessage.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

struct ChatMessagesListResponse: Codable {
    let rows: [ChatMessage]
    let pagination: Pagination
}

struct LastChatMessagesListResponse: Codable {
    let data: [ChatMessage]
}

struct ChatMessage: Codable {
    let id: String
    let chatId: String
    let message: String
    let senderId: String
    let createdAt: Date
    let type: MessageType 
}

extension ChatMessage {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let _id = try container.decode(String.self, forKey: .id)
        let _chatId = try container.decode(String.self, forKey: .chatId)
        let _message = try container.decode(String.self, forKey: .message)
        let _senderId = try container.decode(String.self, forKey: .senderId)

        var value: Date!
        let date = try container.decode(String.self, forKey: .createdAt)
        if let casted = DateFormatters.defaultFormatter().date(from: date) {
            value = casted
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt,
                                                   in: container,
                                                   debugDescription: "Date string does not match format expected by formatter.")
        }
        
        let _type = try MessageType(from: decoder)
        
        self.init(id: _id, chatId: _chatId, message: _message, senderId: _senderId, createdAt: value, type: _type)
    }
}

enum SystemMessageType: String {
    
    case incomingCall
    case outgoingCall
    case callWasAccepted
    case callWasFinished
    case callWasDeclined
    case userDeclinedCall
    case callMeBack
    case unknown
    
    var key: String {
        switch self {
        case .incomingCall:
            return "Incoming call"
        case .outgoingCall:
            return "outgoing call"
        case .callWasAccepted:
            return "The call was accepted"
        case .callWasFinished:
            return "The call is finished"
        case .callWasDeclined:
            return "The call was declined"
        case .userDeclinedCall:
            return "The user declined the call"
        case .callMeBack:
            return "Call me back"
        case .unknown:
            return "unknown"
        }
    }
}

enum MessageType {
    case message
    case system(SystemMessageType)
    
    var type: Int {
        switch self {
        case .message:
            return 0
        default:
            return 1
        }
    }
    
    var value: String? {
        switch self {
        case .message:
            return nil
        case .system(let type):
            return type.rawValue
        }
    }
}

extension MessageType: Codable {
    
    private var rawValue: String {
        switch self {
        case .message:
            return "message"
        default:
            return "call"
        }
    }
    
    enum CodingKeys: CodingKey {
        case type
        case message
    }
    
    enum CodingError: Error {
        case unknownValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.type) {
            let value = try container.decode(String.self, forKey: .type)
            let message = try container.decode(String.self, forKey: .message)
            
            switch value {
            case MessageType.message.rawValue:
                self = .message
            case MessageType.system(SystemMessageType.unknown).rawValue:
                switch message {
                case SystemMessageType.incomingCall.key:
                    self = .system(.incomingCall)
                case SystemMessageType.outgoingCall.key:
                    self = .system(.outgoingCall)
                case SystemMessageType.callWasAccepted.key:
                    self = .system(.callWasAccepted)
                case SystemMessageType.callWasFinished.key:
                    self = .system(.callWasFinished)
                case SystemMessageType.callWasDeclined.key:
                    self = .system(.callWasDeclined)
                case SystemMessageType.userDeclinedCall.key:
                    self = .system(.userDeclinedCall)
                case SystemMessageType.callMeBack.key:
                    self = .system(.callMeBack)
                default:
                    self = .system(.unknown)
                }
                
            default:
                throw CodingError.unknownValue
            }
        } else {
            throw CodingError.unknownValue
        }
    }
    
    func encode(to encoder: Encoder) throws {
        
    }
}
