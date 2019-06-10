//
//  Keychain.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/13/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol KeychainService: class {
    
    var deviceIdentifier: String { get }
    var accessToken: String { get set }
    var refreshToken: String { get set }
    
    @discardableResult func cleanToken() -> Bool
}

private let deviceTokenKey = "deviceTokenKey"
private let accessTokenKey = "AccessTokenKey"
private let refreshTokenKey = "RefreshTokenKey"

class KeychainServiceImplementation: KeychainService {
    
    private let keychain = KeychainSwift(keyPrefix: "Reinforce_")
    static let `default`: KeychainServiceImplementation = KeychainServiceImplementation()
    
    private init() {
        
    }
    
    var deviceIdentifier: String {
        var uuid = UUID().uuidString
        if let deviceIdentiter = self._deviceIdentifier {
            uuid = deviceIdentiter
        } else {
            self._deviceIdentifier = uuid
        }
        
        return uuid
    }
    
    private var _deviceIdentifier: String? {
        get {
            return self.keychain.get(deviceTokenKey) 
        }
        set {
            if let value = newValue {
                self.keychain.set(value, forKey: deviceTokenKey)
            } else {
                self.keychain.delete(deviceTokenKey)
            }
        }
    }
    
    var accessToken: String {
        get {
            if let value = self.keychain.get(accessTokenKey) {
                return value
            } else {
                return ""
            }
        }
        set {
            self.keychain.set(newValue, forKey: accessTokenKey)
        }
    }
    
    var refreshToken: String {
        get {
            if let value = self.keychain.get(refreshTokenKey) {
                return value
            } else {
                return ""
            }
        }
        set {
            self.keychain.set(newValue, forKey: refreshTokenKey)
        }
    }
    
    func cleanToken() -> Bool {
        return self.keychain.delete(refreshTokenKey) && self.keychain.delete(accessTokenKey)
    }
}
