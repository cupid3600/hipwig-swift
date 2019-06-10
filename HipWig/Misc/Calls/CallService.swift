//
//  CallService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/4/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol CallService: class {
    
    var isCallingState: Bool { get }
    var currentOpponent: String? { get }
    var window: UIWindow? { get }
    
    func call(to opponent: User, completion: @escaping () -> Void)
    func handleIncomingCall(call data: IncomingCall)
    func hasActiveCall(_ call: String) -> Bool
    func acceptCall(stream data: StreamData, completion: @escaping VoidHandler)
    func declineCall(opponent: String, completion: @escaping VoidHandler)
    func endCall(opponent: String, removeCallWindow: Bool, completion: VoidHandler?)
    
    func dissmissCallView()
    func checkForCallorDissmissCallWindow(completion: @escaping (Bool) -> Void)
    func resetPrevSession()
}

private let kCurrentOpponentKey = "currentOpponentKey"

fileprivate extension UserDefaults {
    
    class var currentOpponent: String? {
        return UserDefaults.standard.value(forKey: kCurrentOpponentKey) as? String
    }
    
    class func setCurrentOpponent(_ value: String?) {
        UserDefaults.standard.set(value, forKey: kCurrentOpponentKey)
        UserDefaults.standard.synchronize()
    }
}

class CallServiceImplementation: NSObject, CallService {
    
    //MARK: - Properties -
    static let `default`: CallServiceImplementation = CallServiceImplementation()
    
    private let featureFlags = ExpertDetailsFeatureFlagCategoryImplementation.default
    private let api: RequestsManager = RequestsManager.manager
    private let account: AccountManager = AccountManager.manager
    private let application: UIApplication = UIApplication.shared
    private let productService: ProductService = ProductServiceImplementation.default
    private let permissionService: PermissionService = PermissionServiceImplementation()
    
    var window: UIWindow? { return CallServiceImplementation.callWindow }
    private static var callWindow: UIWindow?
    private var rootViewController: UINavigationController? { return CallServiceImplementation.callWindow?.rootViewController as? UINavigationController }
    private var acceptCallClosure: (() -> Void)?
    private lazy var pushService: PushHandler = PushHandler.handler
    
    var isCallingState: Bool {
        if CallServiceImplementation.callWindow != nil {
            if let target = self.rootViewController {
                
                let isStartStreamScreen = target.viewControllers.first is StartStreamViewController
                let isStreamScreen = target.viewControllers.first is StreamViewController
                let isAcceptStreamScreen = target.viewControllers.first is AcceptStreamViewController
                
                if isStartStreamScreen || isStreamScreen || isAcceptStreamScreen {
                    return self.currentOpponent != nil
                }
            }
        }
        
        return false
    }
    
    private (set) var currentOpponent: String? {
        get {
            return UserDefaults.currentOpponent
        }
        set {
            UserDefaults.setCurrentOpponent(newValue)
        }
    }
    
    override init() {
        super.init()
        
        NotificationCenter.addDeclineCallObserver { [weak self] in
            self?.dissmissCallView()
        }
        
        NotificationCenter.addEndCallObserver { [weak self] in
            self?.dissmissCallView()
        }
        
        NotificationCenter.addRoleChangeObserver { [weak self] in
            if let opponent = UserDefaults.currentOpponent {
                self?.endCall(opponent: opponent, removeCallWindow: true)
            }
        }
        
        NotificationCenter.addAcceptCallObserver { [weak self] in
            self?.acceptCallClosure?()
            self?.acceptCallClosure = nil
        }
    }
    
    //MARK: - CallService -
    func checkForCallorDissmissCallWindow(completion: @escaping (Bool) -> Void) {
        self.pushService.checkForCallifAvailable(completion: completion) 
    }
    
    func hasActiveCall(_ opponent: String) -> Bool {
        if self.currentOpponent != nil {
            return self.currentOpponent != opponent
        } else {
            return false
        }
    }
    
    func resetPrevSession() {
        self.currentOpponent = nil
    }
    
    func acceptCall(stream data: StreamData, completion: @escaping VoidHandler) {
        if !reachability.isNetworkReachable {
            ModalStoryboard.showUnavailableNetwork()
            completion()
        } else {
            self.api.acceptCall(receiver: data.userId) { [weak self] error in
                completion()
                
                if let error = error {
                    logger.log(error)
                } else {
                    if let source = self?.rootViewController {
                        CallStoryboard.showStream(data: data, from: source)
                    }
                } 
            }
        }
    }
    
    func declineCall(opponent: String, completion: @escaping VoidHandler) {
        self.pushService.setEndCall(for: opponent)
        
        if !reachability.isNetworkReachable {
            self.dissmissCallView()
            ModalStoryboard.showUnavailableNetwork()
            
            completion()
        } else {
            self.api.declineCall(receiver: opponent) { [weak self] error in
                completion()
                
                if let error = error {
                    logger.log(error)
                }
                
                self?.dissmissCallView()
            }
        }
    }
    
    func endCall(opponent: String, removeCallWindow: Bool, completion: (() -> Void)? = nil) {
        self.pushService.setEndCall(for: opponent)
        
        if !reachability.isNetworkReachable {
            if removeCallWindow {
                self.dissmissCallView()
            }
            
            ModalStoryboard.showUnavailableNetwork()
            completion?()
        } else {
            self.api.finishCall(opponentID: opponent) { error in
                
                if let error = error {
                    logger.log(error)
                }
                
                completion?()
            }
            
            if removeCallWindow {
                self.dissmissCallView()
            }
        }
    }
    
    func handleIncomingCall(call: IncomingCall) {
        self.currentOpponent = call.opponent
        
        self.showIncominCallView(with: call)
    }
    
    func call(to receiver: User, completion: @escaping () -> Void) {
        self.currentOpponent = receiver.id
        
        self.permissionService.check(for: .makeCall(to: receiver)) { [weak self] canMakeCall in
            guard let `self` = self else { return }
            
            if canMakeCall {
                self.showOutgoingCallView(with: receiver)
                self.createCallAndShowCallView(opponent: receiver)
            } else {
                self.currentOpponent = nil
            }
            
            completion()
        }
    }
    
    private func continueCall(to opponent: User) {
        self.showOutgoingCallView(with: opponent)
        self.createCallAndShowCallView(opponent: opponent)
    }
        
    func dissmissCallView() {
        self.currentOpponent = nil
        self.destroyCallWindow()
    }
    
    //MARK: - Private -
    private func createCallAndShowCallView(opponent: User) {
        var userID: String?
        var expertID: String?
        
        if self.account.role == .user {
            expertID = opponent.id
        } else {
            userID = opponent.id
        }
        
        self.api.createCall(userID: userID, expertID: expertID) { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let data):
                #if targetEnvironment(simulator)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                        self.showCallView(opponent: opponent, session: data.session, token: data.token)
                    }
                #else
                    self.acceptCallClosure = { [weak self] in
                        self?.showCallView(opponent: opponent, session: data.session, token: data.token)
                    } 
                #endif
                
            case .failure(let error):
                logger.log(error)
            }
        }
    }
    
    //MARK: - Show view
    private func showCallView(opponent: User, session: String, token: String) {
        let data = StreamData(avatar: opponent.profileImage, userName: opponent.name, userId: opponent.id, session: session, token: token)
        if let source = self.rootViewController {
            CallStoryboard.showStream(data: data, from: source)
        }
    }
    
    private func showIncominCallView(with call: IncomingCall) {
        let viewController: AcceptStreamViewController = CallStoryboard.incomingCallViewController
        viewController.call = call

        self.prepareCallWindow()
        self.setupRootNavigationController(with: viewController)
    }
    
    private func showOutgoingCallView(with opponent: User) {
        let viewController = CallStoryboard.startVideoChatViewController
        viewController.opponent = opponent
        
        self.prepareCallWindow()
        self.setupRootNavigationController(with: viewController)
    }
    
    private func setupRootNavigationController(with target: UIViewController) {
        let navigationContoller = UINavigationController(rootViewController: target)
        navigationContoller.isNavigationBarHidden = true
        
        if let window = CallServiceImplementation.callWindow {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                CallServiceImplementation.callWindow?.rootViewController = navigationContoller
            }, completion: { _ in
                
            })
        }
    }
    
    //MARK: - Window -
    private func prepareCallWindow() {
        self.application.keyWindow?.endEditing(true)

        CallServiceImplementation.callWindow = UIWindow(frame: UIScreen.main.bounds)
        CallServiceImplementation.callWindow?.windowLevel = .statusBar - 1
        
        CallServiceImplementation.callWindow?.makeKeyAndVisible()
        
        NotificationCenter.postDisplayCallWindowEvent()
    }
    
    private func destroyCallWindow() {
        
        var windowBeenDeleted: Bool = false
        if CallServiceImplementation.callWindow != nil {
            windowBeenDeleted = true
            NotificationCenter.postWillDestroyCallWindowEvent()
        }
        
        CallServiceImplementation.callWindow?.rootViewController = nil
        CallServiceImplementation.callWindow?.isHidden = true
        CallServiceImplementation.callWindow = nil
        
        if windowBeenDeleted {
            NotificationCenter.postDestroyCallWindowEvent()
        }
    }
}
