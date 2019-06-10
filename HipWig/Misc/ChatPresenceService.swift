//
//  ChatPresenceService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/29/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol ChatPresenceService {

    var selectedChatId: String? { get }
    var loadingChat: Bool { get }
    
    func set(chatId: String?)
    func setLoadingChat()
}

class ChatPresenceServiceImplementation: ChatPresenceService {
    
    static let `default`: ChatPresenceServiceImplementation = ChatPresenceServiceImplementation() 
    
    private (set) var selectedChatId: String?
    private (set) var loadingChat: Bool = false
    
    private init() {
        
    }
    
    func set(chatId: String?) {
        self.selectedChatId = chatId
        self.loadingChat = false
    }
    
    func setLoadingChat() {
        self.loadingChat = true
    }
}
