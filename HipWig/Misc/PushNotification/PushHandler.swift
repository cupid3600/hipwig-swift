//
//  PushHandler.swift
//  HipWig
//
//  Created by Alexey on 1/31/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation 
import SVProgressHUD
import UserNotifications

enum EventReceiveState {
    case active
    case inactive
    case background
    case none
} 

enum EventSourceType {
    case pushNotification
    case voipNotification(Bool)
}

enum TokenType: String {
    case VOIP
    case DEFAULT
}

protocol PushService: class, UNUserNotificationCenterDelegate {
    func update(pushToken token: String, type: TokenType)
    func handlePayload(info: [AnyHashable : Any], in state: EventReceiveState, source: EventSourceType)
    func setEndCall(for opponent: String)
}

typealias HandleIncomingCallResult = (incomingCallHandled: Bool, call: IncomingCall)

class PushHandler: NSObject, PushService {
    
    public static let handler = PushHandler()

    private let callService: CallService = CallServiceImplementation.default
    private let api: RequestsManager = RequestsManager.manager
    private let account: AccountManager = AccountManager.manager
    private let shared: SharedStorage = SharedStorageImplementation.default
    private let pushRestrictions: PushRestrictionsHandler = PushRestrictionsHandler()
    private let keychinService: KeychainService = KeychainServiceImplementation.default
    private let messageService: MessageService = MessageServiceImplementation.default
    
    override init() {
        super.init()
        
        let checkForCallifAvailableClosure =  { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.checkForCallifAvailable()
        }
        
        NotificationCenter.addMainScreenDidLoadedObserver(completion: checkForCallifAvailableClosure)
        NotificationCenter.addCheckIncomingCallObserver(completion: checkForCallifAvailableClosure)
        NotificationCenter.addDestroyCallWindowObserver(completion: checkForCallifAvailableClosure)
        
        NotificationCenter.addApplicationWillTerminateObserver {
            if let data = self.shared.firstReceivedCallInfo {
                self.shared.setEndCallFor(data.user)
            }
        }
    }
    
    public func checkForCallifAvailable(completion: ((Bool) -> Void)? = nil) {
        if let data = self.shared.firstReceivedCallInfo, let info = data.info {
            guard let type = info["type"] as? String, let notificationType = PushNotificationType(type) else {
                completion?(false)
                return
            }
            
            switch notificationType {
            case .call(let callEvent):
                let opponentValue = info["partnerId"] as? String
                let state = UIApplication.shared.eventState
                
                if let opponent = opponentValue, state == .active && !self.callService.hasActiveCall(opponent) && !self.callService.isCallingState {
                    DispatchQueue.main.async {
                        self.handleCallEventPayload(info: info, callEvent: callEvent, from: opponent)
                        completion?(true)
                    }
                } else {
                    completion?(false)
                }
                
                if let opponent = opponentValue {
                    self.cancelDeliveredIncomingCallNotifications(from: opponent)
                }
            default:
                break
            }
        } else {
            completion?(false)
        }
    }
    
    public func setEndCall(for opponent: String) {
        self.shared.setEndCallFor(opponent)
    }
    
    public func update(pushToken token: String, type: TokenType) {
        self.account.unarchiveUser()
        
        let isUserLoggedIn = self.account.user != nil
        let canReffreshToken = !self.keychinService.accessToken.isEmpty && !self.keychinService.refreshToken.isEmpty
        
        if canReffreshToken && isUserLoggedIn {
            let uuid = self.keychinService.deviceIdentifier
            self.api.updatePushToken(pushToken: token, deviceToken: uuid, type: type) { error in
                if let error = error {
                    logger.log(error)
                }
            }
        }
    }
    
    public func handlePayload(info: [AnyHashable : Any], in receiveEventAppState: EventReceiveState, source: EventSourceType) {
        guard let type = info["type"] as? String, let notificationType = PushNotificationType(type) else {
            return
        }
        
        switch notificationType {
        case .call(let callEvent):
            switch source {
            case .voipNotification(let whenPushSelected):
                let opponent = info["userId"] as? String
                
                if whenPushSelected {
                    self.handleCallEventPayload(info: info, callEvent: callEvent, from: opponent)
                } else {
                    let partnerValue = info["partnerId"] as? String
                    
                    if let partner = partnerValue {
                        self.shared.set(call: info, for: partner)
                    }
                    
                    if receiveEventAppState == .active {
                        self.handleCallEventPayload(info: info, callEvent: callEvent, from: opponent)
                    } else {
                        if callEvent == .incomingCall {
                            if let partner = partnerValue {
                                self.showLocalNotification(info: info, partner: partner)
                            }
                        } else {
                            self.handleCallEventPayload(info: info, callEvent: callEvent, from: opponent)
                        }
                    }
                }
            default:
                break
            }
        case .message:
            self.handleIncomingMessage(info: info, in: receiveEventAppState)
        case .system(let systemEvent):
            self.handleSystemEventPayload(info: info, systemEvent: systemEvent)
        }
    }
    
    private func handleCallEventPayload(info: [AnyHashable : Any], callEvent: CallEvent, from opponent: String?) {
        let currentOpponent = self.callService.currentOpponent
        
        if callEvent == .acceptCall {
            if self.pushRestrictions.canPerform(for: opponent, currentOpponent: currentOpponent) {
                NotificationCenter.postAcceptCallEvent()
            }

        } else if callEvent == .declineCall {
            if let user = opponent {
                self.shared.setEndCallFor(user)
            }
            
            if self.pushRestrictions.canPerform(for: opponent, currentOpponent: currentOpponent) {
                NotificationCenter.postDeclineCallEvent()
            }

        } else if callEvent == .endCall {
            if let user = opponent {
                self.shared.setEndCallFor(user)
            }
            
            if self.pushRestrictions.canPerform(for: opponent, currentOpponent: currentOpponent) {
                NotificationCenter.postEndCallEvent()
            }

        } else if callEvent == .incomingCall {
            if let incomingCallHandleInfo = self.handleIncomingCall(info: info) {
                if !incomingCallHandleInfo.incomingCallHandled {
                    self.callBack(to: incomingCallHandleInfo.call.opponent)
                }
            }
        } else if callEvent == .pauseCall {
            if self.pushRestrictions.canPerform(for: opponent, currentOpponent: currentOpponent) {
                NotificationCenter.postPauseCallEvent()
            }
 
        } else if callEvent == .resumeCall {
            if self.pushRestrictions.canPerform(for: opponent, currentOpponent: currentOpponent) {
                NotificationCenter.postResumeCallEvent()
            }
        }
    }
    
    private func handleSystemEventPayload(info: [AnyHashable : Any], systemEvent event: SystemEvent) {
        let opponent = info["userId"] as? String
        
        if event == .switchRole {
            NotificationCenter.postRoleChangeEvent()
        } else if event == .logout {
            self.account.logoutAndLoginIfNeeded()
        } else if event == .blockUser {
            NotificationCenter.postBlockUserEvent(opponent)
        } else if event == .unblockUser {
            NotificationCenter.postUnBlockUserEvent(opponent)
        }
    }
    
    private func handleIncomingCall(info: [AnyHashable : Any]) -> HandleIncomingCallResult? {
        if self.account.canAcceptCall {
            if let call = IncomingCall(info: info) {
                
                if self.callService.hasActiveCall(call.opponent) {
                    self.account.fetchUser(id: call.opponent) { user in
                        ModalStoryboard.showCallNotification(with: user)
                    }
                    return nil
                } else {
                    let result = self.shared.checkForCall(with: call.opponent)
                    if let hasActiveCall = result.hasActiveCall {
                        if hasActiveCall {
                            self.callService.handleIncomingCall(call: call)
                        }
                        
                        return (incomingCallHandled: hasActiveCall, call: call)
                    } else {
                        return (incomingCallHandled: false, call: call)
                    }
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func callBack(to opponent: String) {
        self.account.fetchUser(id: opponent) { [weak self] user in
            guard let `self` = self else { return }
            
            if !self.callService.isCallingState {
                self.callService.call(to: user) {
                    
                }
            }
        }
    }
    
    private func handleIncomingMessage(info: [AnyHashable : Any], in receiveEventAppState: EventReceiveState) {
        guard let message = info["chat"] as? [AnyHashable : Any] else {
            return
        }
        
        if let conversation = Notification.conversation(from: message) {
            self.messageService.hasChat(conversation.id) { hasConversation in
                if receiveEventAppState == .none {
                    NotificationCenter.addMainScreenDidLoadedObserver {
                        NotificationCenter.postRecieveNewMessageEvent(with: receiveEventAppState, message: message)
                    }
                } else {
                    NotificationCenter.postRecieveNewMessageEvent(with: receiveEventAppState, message: message)
                }
            }
        }
    }
    
    private func showLocalNotification(info: [AnyHashable : Any], partner: String) {
        if let notificationContent = LocalNotificationContent(info: info) {
            AppDelegate.shared.scheduleLocalPushNotification(notificationContent.localNotification)
        }
    }
    
    private func cancelDeliveredIncomingCallNotifications(from user: String) {
        AppDelegate.shared.getDeliveredNotificationIdentifiers(completion: { ids in
            AppDelegate.shared.cancelDeliveredNotifications(ids: ids)
        }) { notification in
            let info = notification.request.content.userInfo
            guard let type = info["type"] as? String, let notificationType = PushNotificationType(type), let initiator = info["partnerId"] as? String else {
                return false
            }
            
            switch notificationType {
            case .call(let callEvent):
                return callEvent == .incomingCall && user == initiator
            default:
                return false
            }
        }
    }
}
