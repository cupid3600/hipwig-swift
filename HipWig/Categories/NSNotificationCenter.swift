//
//  NSNotificationCenter+Logout.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/7/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension NotificationCenter {
    
    class func addItemDidPlayToEndTimeObserver(_ item: AnyObject? = nil, completion: @escaping (AVPlayerItem) -> Void) {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { notification in
            guard let finishedItem = notification.object as? AVPlayerItem else { return }
            completion(finishedItem)
        }
    }
    
    class func removeItemDidPlayToEndTimeObserver(sender: AnyObject, _ item: AnyObject? = nil) {
        NotificationCenter.default.removeObserver(sender, name: .AVPlayerItemDidPlayToEndTime, object: item)
    }
    
    class func addRecieveNewMessageObserver(completion: @escaping (_ message: Conversation, _ state: EventReceiveState) -> Void) {
        NotificationCenter.default.addObserver(forName: .IncomingTextMesage, object: nil, queue: .main) { notification in
            guard let conversation = notification.conversation, let state = notification.object as? EventReceiveState else {
                return
            }
            
            completion(conversation, state)
        }
    }
    
    class func postRecieveNewMessageEvent(with state: EventReceiveState, message: [AnyHashable : Any]) {
        NotificationCenter.default.post(name: .IncomingTextMesage, object: state, userInfo: message)
    }
    
    class func postMainScreenDidLoadedEvent() {
        NotificationCenter.default.post(name: .MainScreenLoaded, object: nil, userInfo: nil)
    }
    
    class func addMainScreenDidLoadedObserver(completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .MainScreenLoaded, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addAcceptCallObserver(completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .AcceptCallAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addDeclineCallObserver(completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .DeclineCallAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addEndCallObserver(completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .EndCallAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addDestroyCallWindowObserver(completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .DestroyCallWindowAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addWillDestroyCallWindowObserver(completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .WillDestroyCallWindowAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addDisplayCallWindowObserver(completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .DisplayCallWindowAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addRoleChangeObserver(completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .RoleChangeAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func postAcceptCallEvent() {
        NotificationCenter.default.post(name: .AcceptCallAction, object: nil, userInfo: nil)
    }
    
    class func postDeclineCallEvent() {
        NotificationCenter.default.post(name: .DeclineCallAction, object: nil, userInfo: nil)
    }
    
    class func postDestroyCallWindowEvent() {
        NotificationCenter.default.post(name: .DestroyCallWindowAction, object: nil, userInfo: nil)
    }
    
    class func postWillDestroyCallWindowEvent() {
        NotificationCenter.default.post(name: .WillDestroyCallWindowAction, object: nil, userInfo: nil)
    }
    
    class func postDisplayCallWindowEvent() {
        NotificationCenter.default.post(name: .DisplayCallWindowAction, object: nil, userInfo: nil)
    }
    
    class func postEndCallEvent() {
        NotificationCenter.default.post(name: .EndCallAction, object: nil, userInfo: nil)
    }
    
    class func postRoleChangeEvent() {
        NotificationCenter.default.post(name: .RoleChangeAction, object: nil, userInfo: nil)
    }
    
    class func postBlockUserEvent(_ sender: String?) {
        NotificationCenter.default.post(name: .BlockUserAction, object: sender, userInfo: nil)
    }
    
    class func postUnBlockUserEvent(_ sender: String?) {
        NotificationCenter.default.post(name: .UnBlockUserAction, object: sender, userInfo: nil)
    }
    
    class func postPauseCallEvent() {
        NotificationCenter.default.post(name: .PauseCallAction, object: nil, userInfo: nil)
    }
    
    class func postResumeCallEvent() {
        NotificationCenter.default.post(name: .ResumeCallAction, object: nil, userInfo: nil)
    }
    
    class func postCheckIncomingCallEvent() {
        NotificationCenter.default.post(name: .CheckForIncomingCallAction, object: nil, userInfo: nil)
    }
    
    class func postNotificationStatusChangeEvent(_ value: Bool) {
        NotificationCenter.default.post(name: .NotificationStateChangeAction, object: value, userInfo: nil)
    }
    
    class func addBlockUserObserver(_ completion: @escaping (String) -> Void) {
        NotificationCenter.default.addObserver(forName: .BlockUserAction, object: nil, queue: .main) { notification in
            if let sender = notification.object as? String {
                completion(sender)
            }
        }
    }
    
    class func addUnBlockUserObserver(_ completion: @escaping (String) -> Void) {
        NotificationCenter.default.addObserver(forName: .UnBlockUserAction, object: nil, queue: .main) { notification in
            if let sender = notification.object as? String {
                completion(sender)
            }
        }
    }
    
    class func addNotificationStatusChangeObserver(_ completion: @escaping (Bool) -> Void) {
        NotificationCenter.default.addObserver(forName: .NotificationStateChangeAction, object: nil, queue: .main) { notification in
            if let value = notification.object as? Bool {
                completion(value)
            }
        }
    }
    
    class func addPauseCallObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .PauseCallAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addResumeCallObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .ResumeCallAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addHideKeyboardObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addDidShowKeyboardObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addWillEnterForegroundObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    
    class func addApplicationWillTerminateObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addApplicationResignActiveObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addApplicationDidBecomeActiveObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addApplicationWillEnterForegroundObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addApplicationDidEnterBackgroundObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    class func addCheckIncomingCallObserver(completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .CheckForIncomingCallAction, object: nil, queue: .main) { _ in
            completion()
        }
    }
    
    typealias AVAudioSessionInteraption = (type: AVAudioSession.InterruptionType, options: AVAudioSession.InterruptionOptions?)
    class func addAVInteraptionObserver(with completion: @escaping (AVAudioSessionInteraption?) -> Void) {
        let object = AVAudioSession.sharedInstance()
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: object, queue: .main) { notification in
            guard let info = notification.userInfo,
                let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                    completion(nil)
                    
                    return
            }
            
            var option: AVAudioSession.InterruptionOptions?
            if let optionValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                option = AVAudioSession.InterruptionOptions(rawValue: optionValue)
            }
            
            let result = (type, option)
            
            completion(result)
        }
    }
    
    class func addRouteChangeObserver(with completion: @escaping () -> Void) {
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { notification in
            //    NSDictionary *dict = notif.userInfo;
            //    AVAudioSessionRouteDescription *routeDesc = dict[AVAudioSessionRouteChangePreviousRouteKey];
            //    AVAudioSessionPortDescription *prevPort = [routeDesc.outputs objectAtIndex:0];
            //    if ([prevPort.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            //    //Head phone removed
            //    }
            
            completion()
        }
    }

}

