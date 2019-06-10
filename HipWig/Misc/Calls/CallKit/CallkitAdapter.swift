////
////  CallkitAdapter.swift
////  HipWig
////
////  Created by Vladyslav Shepitko on 4/10/19.
////  Copyright © 2019 HipWig. All rights reserved.
////
//
//import CallKit
//
//class CallkitAdapter: NSObject {
//    
//    private let callManager: CallManager
//    private let provider: CXProvider
//    
//    convenience override init() {
//        let manager = CallManager()
//        self.init(callManager: manager)
//    }
//    
//    init(callManager manager: CallManager) {
//        self.callManager = manager
//        self.provider = CXProvider(configuration: type(of: self).configuration)
//        
//        super.init()
//        self.provider.setDelegate(self, queue: nil)
//    }
//    
//    var isCallKitAvailable: Bool {
//        if #available(iOS 10.0, *) {
//            return true
//        } else {
//            return false
//        }
//    }
//    
//    static let configuration: CXProviderConfiguration = {
//        let appName = UIApplication.shared.applicationName
//        let config = CXProviderConfiguration(localizedName: appName)
//        
//        config.supportsVideo = true
//        config.maximumCallsPerCallGroup = 1
//        config.maximumCallGroups = 1
//        config.supportedHandleTypes = [.phoneNumber]
//        config.iconTemplateImageData = UIImage(named: "AppIcon")?.pngData()
//        config.ringtoneSound = "ringtone.wav"
//        
//        return config
//    }()
//    
//}
//
//extension CallkitAdapter: CXProviderDelegate {
//    
//    func providerDidReset(_ provider: CXProvider) {
//        
//    }
//}
//
//
//class CallManager {
//
//    let callController = CXCallController()
//    
//    // MARK: Actions
//    
//    func startCall(handle: String, video: Bool = true, completion: @escaping (Bool) -> Void) {
//        let handle = CXHandle(type: .phoneNumber, value: handle)
//        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
//        
//        startCallAction.isVideo = video
//        
//        let transaction = CXTransaction()
//        transaction.addAction(startCallAction)
//        
//        self.requestTransaction(transaction, action: "startCall", completion: completion)
//    }
//    
////    func end(call: SpeakerboxCall) {
////        let endCallAction = CXEndCallAction(call: call.uuid)
////        let transaction = CXTransaction()
////        transaction.addAction(endCallAction)
////
////        requestTransaction(transaction, action: "endCall")
////    }
////
////    func setHeld(call: SpeakerboxCall, onHold: Bool) {
////        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
////        let transaction = CXTransaction()
////        transaction.addAction(setHeldCallAction)
////
////        requestTransaction(transaction, action: "holdCall")
////    }
//    
//    private func requestTransaction(_ transaction: CXTransaction, action: String = "", completion: @escaping (Bool) -> Void) {
//        callController.request(transaction) { error in
//            if let error = error {
//                print("Error requesting transaction: \(error)")
//            } else {
//                print("Requested transaction \(action) successfully")
//            }
//            
//            completion(error == nil)
//        }
//    }
//    
//    // MARK: Call Management
//    
//    static let CallsChangedNotification = Notification.Name("CallManagerCallsChangedNotification")
//    
////    private(set) var calls = [SpeakerboxCall]()
////
////    func callWithUUID(uuid: UUID) -> SpeakerboxCall? {
////        guard let index = calls.index(where: { $0.uuid == uuid }) else {
////            return nil
////        }
////        return calls[index]
////    }
////
////    func addCall(_ call: SpeakerboxCall) {
////        calls.append(call)
////
////        call.stateDidChange = { [weak self] in
////            self?.postCallsChangedNotification()
////        }
////
////        postCallsChangedNotification()
////    }
////
////    func removeCall(_ call: SpeakerboxCall) {
////        calls = calls.filter {$0 === call}
////        postCallsChangedNotification()
////    }
////
//    func removeAllCalls() {
////        calls.removeAll()
//        postCallsChangedNotification()
//    }
//    
//    private func postCallsChangedNotification() {
//        NotificationCenter.default.post(name: type(of: self).CallsChangedNotification, object: self)
//    }
//}
