//
//  AccountManager.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import JWTDecode
import GoogleSignIn
import FBSDKLoginKit
import Alamofire

enum AccessTokenStatus: Int {
    case absent
    case working
    case expired
    case expireSoon
}

private var documentsDirectory: URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

class AccountManager {
    
    static public var manager = AccountManager()
    
    private let api: RequestsManager = RequestsManager.manager
    private let category = ExpertDetailsFeatureFlagCategoryImplementation.default
    private let keychain: KeychainService = KeychainServiceImplementation.default
    private lazy var messageService: MessageService = MessageServiceImplementation.default
    
    private (set) var user: User?
    private (set) var inLogoutState: Bool = false
    
    public var myUserID: String? {
        get {
            return self.user?.id
        }
    }

    public func setUser(user: User) {
        self.user = user
        self.saveCurrentUser()
    }

    public var role: Role {
        return self.user?.role ?? .unknown
    }
    
    var needSendTime: Bool {
        switch self.role {
        case .user:
            return true
        default:
            return false
        }
    }
    
    var canAcceptCall: Bool {
        
        if self.myUserID == nil {
            self.api.unarchiveUserData()
        }
        
        guard let user = self.user else {
            return false
        }
        
        if self.myUserID == nil || self.inLogoutState || (self.role == .expert && !user.isAvailable) {
            return false
        } else {
            return true
        }
    }
    
    var needShowTabBar: Bool {
        if let user = self.user {
            let isFreePlan = category.freeCalls || category.freeMessages
            
            return user.role == .user && user.subscribed || user.role == .expert || isFreePlan
        } else {
            return false
        }
    }
    
    var availableTime: TimeInterval {
        if self.role == .expert {
            return .infinity
        } else {
            if self.category.freeMinutes {
                return .infinity
            } else {
                if let user = self.user {
                    return user.availableTime
                } else {
                    return 0.0
                } 
            }
        }
    }
    
    var hasAvailableTime: Bool {
        return self.availableTime > 1.0
    }
    
    public var isSubscribed: Bool {
        if self.role == .expert {
            return false
        } else {
            if let user = self.user {
                return user.subscribed
            } else {
                return false
            }
        }
    }
    
    private init() {
        
    }
    
    public func logoutAndLoginIfNeeded() {
        self.logout { error in
            if let error = error {
                logger.log(error)
                ModalStoryboard.show(error: error.localizedDescription)
            } else {
                MainStoryboard.showLogin()
            }
        }
    }

    public func logout(_ completion: @escaping ErrorHandler) {
        self.inLogoutState = true
        
        self.api.logout { error in
            self.inLogoutState = false
            
            if let error = error {
                completion(error)
            } else {
                self.user = nil
                self.messageService.clean()
                self.keychain.cleanToken()
                Instagram.shared.logout()
                GIDSignIn.sharedInstance().signOut()
                LoginManager().logOut()
                
                let userPath = documentsDirectory.appendingPathComponent("user_data.raw")
                
                do {
                    try FileManager.default.removeItem(at: userPath)
                } catch {
                    print("[Account manager]: couldn't clear data")
                }
                
                self.resetDefaults()
                
                completion(nil)
            }
        }
    }
    
    func resetDefaults() {
        UserDefaults.filter = ExpertsFilter(purpose: nil, sex: nil, location: nil)
    }

    public var tokenStatus: AccessTokenStatus {
        return self.keychain.accessToken.JWTtokenStatus
    }
    
    func fetchUser(id: String, completion: @escaping (User) -> Void) {
        self.api.fetchUser(id: id) { result in
            switch result {
            case .success(let user):
                completion(user)
            case .failure(let error):
                logger.log(error)
            }
        }
    }

    public func refreshUserTokens(completion: @escaping (_ error: Error?) -> Void) {

        self.api.refreshToken(accessToken: self.keychain.accessToken, refreshToken: self.keychain.refreshToken) { [weak self] response in
            guard let `self` = self else {
                completion(RequestsManagerError.noData)
                return
            }
            
            switch response.result {
            case .success:
                guard let data = response.result.value as? [String : String] else {
                    completion(RequestsManagerError.noData)
                    return
                }
                
                if let accessToken = data["accessToken"], let refreshToken = data["refreshToken"] {
                    self.keychain.accessToken = accessToken
                    self.keychain.refreshToken = refreshToken
                } else {
                    self.keychain.cleanToken()
                }
                
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }

    }

    public func unarchiveUser() {
        let fullPath = documentsDirectory.appendingPathComponent("user_data.raw")
        do {
            let data = try Data.init(contentsOf: fullPath)
            if let userJSON = String(bytes: data, encoding: .utf8) {
                debugPrint(userJSON)
            }
            
            self.user = try JSONDecoder().decode(User.self, from: data)
        } catch {
            logger.log(error)
        }
    }
    
    public func canResumeSession(completion: @escaping (Bool) -> Void) {
        self.unarchiveUser()
        if let userId = AccountManager.manager.myUserID {
            self.api.fetchUser(id: userId) { result in
                switch result {
                case .success:
                    completion(true)
                case .failure:
                    completion(false)
                }
            }
        } else {
            completion(false)
        }
    }
    
    public func updateUser(completion: @escaping () -> Void) {
        
        if let userId = AccountManager.manager.myUserID {
            self.api.fetchUser(id: userId) { [weak self] result in
                guard let `self` = self else {
                    completion()
                    return
                }
                
                switch result {
                case .success(let user):
                    self.setUser(user: user)
                case .failure(let error):
                    logger.log(error)
                }
                
                completion()
            }
        } else {
            completion()
        }
    }

    public var userInfo: [String: Any] {
        var data: [String: Any] = [:]
        data["name"] = self.user?.name
        data["email"] = self.user?.email
        data["available_seconds"] = self.user?.availableTime
        data["gender"] = self.user?.expert?.gender.rawValue
        data["user_id"] = self.user?.id

        return data
    }

    private func saveCurrentUser() {
        do {
            let data = try JSONEncoder().encode(self.user)
            
            if let userJSON = String(bytes: data, encoding: .utf8) {
                debugPrint(userJSON)
            }
            
            let fullPath = documentsDirectory.appendingPathComponent("user_data.raw")
        
            try data.write(to: fullPath)
        } catch {
            print("[Account manager]: couldn't write file")
        }
    } 
}
