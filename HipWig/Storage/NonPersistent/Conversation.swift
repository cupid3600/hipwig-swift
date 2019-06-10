//
//  ConversationStuff.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

struct ConversationsListResponse: Codable {
    let rows: [Conversation]
    let pagination: Pagination
}

extension ConversationsListResponse {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let _rows = try container.decode([Conversation].self, forKey: .rows)
        let _pagination = try container.decode(Pagination.self, forKey: .pagination)

        self.init(rows: _rows, pagination: _pagination)
    }
}

struct Conversation: Codable, Equatable {
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool{
        return lhs.id == rhs.id
    }
    
    var id: String
    var users: [User]
    var lastMessage: ChatMessage?
    var unreadCount: Int
    var opponent: User
    var me: User
}

enum ConversationParseError: Error {
    case parseError
}

extension Conversation {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let _id = try container.decode(String.self, forKey: .id)
        let _users = try container.decode([User].self, forKey: .users)
        let _unreadCount = try container.decode(Int.self, forKey: .unreadCount)

        let _lastMessage: ChatMessage?
        do {
            _lastMessage = try container.decode(ChatMessage.self, forKey: .lastMessage)
        }
        catch {
            _lastMessage = nil
        }

        let _opponent: User!
        let _me: User!
        
        let first = _users[0]
        if first.id == AccountManager.manager.myUserID {
            _me = first
            if _users.count > 1 {
                _opponent = _users[1]
            } else {
                _opponent = first
            }
        } else {
            if _users.count > 1 {
            _me = _users[1]
            _opponent = first
            } else {
                _opponent = first
                _me = first
            }
        }
        
        self.init(id: _id, users: _users, lastMessage: _lastMessage, unreadCount: _unreadCount, opponent: _opponent, me: _me)
    }
}
