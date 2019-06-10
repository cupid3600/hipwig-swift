//
//  PushNotificationType.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/6/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

enum CallEvent: String {
    case incomingCall = "NewCall"
    case acceptCall = "AcceptCall"
    case declineCall = "DeclineCall"
    case endCall = "EndCall"
    case pauseCall = "PauseCall"
    case resumeCall = "UnpauseCall"
}

enum SystemEvent: String {
    case switchRole = "SwitchRole"
    case logout = "Logout"
    case blockUser = "BlockUser"
    case unblockUser = "UnblockUser"
}

enum MessageEvent: String {
    case message = "SendMessage"
}

enum PushNotificationType {
    case call(CallEvent)
    case message
    case system(SystemEvent)
    
    init?(_ value: String) {
        if let callEvent = CallEvent(rawValue: value) {
            self = .call(callEvent)
        } else if let systemEvent = SystemEvent(rawValue: value) {
            self = .system(systemEvent)
        } else if let _ = MessageEvent(rawValue: value) {
            self = .message
        } else {
            return nil
        }
    }
}
