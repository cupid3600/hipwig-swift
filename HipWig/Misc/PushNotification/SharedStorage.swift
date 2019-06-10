//
//  SharedStorage.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/6/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol SharedStorage: class {
    
    var firstReceivedCallInfo: (info: [AnyHashable : Any]?, user: String)? { get }
    var notifications: [[AnyHashable : Any]] { get }
    
    func set(call info:[AnyHashable : Any], for user: String)
    func removeCallInfo(for user: String)
    
    func checkForCall(with user: String) -> (info: [AnyHashable : Any]?, hasActiveCall: Bool?)
    func setEndCallFor(_ user: String)
    
    func removeAll()
}

private let kNotificationInfoKey = "kNotificationInfoKey"
private let callInfoPrefix = "callInfoPrefix"
private let callStatePrefix = "callStatePrefix"

class SharedStorageImplementation: NSObject, SharedStorage {
    
    static let `default` = SharedStorageImplementation()
    private let defaults = UserDefaults(suiteName: kSharedDefaults)
    
    private override init() {
        
    }
    
    var firstReceivedCallInfo: (info: [AnyHashable : Any]?, user: String)? {
        guard let defaults = self.defaults else { return nil }
        
        let keys = defaults.dictionaryRepresentation().keys.map{ $0 }
        let users = keys.filter{ $0.contains(callInfoPrefix) }.map{ $0.replacingOccurrences(of: "_" + callInfoPrefix, with: "") }
        
        let infoList = users.map{ user in (self.checkForCall(with: user), user) }.compactMap{ (info: $0.0.info, user: $0.1) }
        
        let sortedCalls = infoList.sorted { (data1, data2) -> Bool in
            guard let date1 = data1.info?["date"] as? Int else { return false }
            guard let date2 = data2.info?["date"] as? Int else { return false }
            
            return date1 < date2
        }
        
        let result = sortedCalls.map{ ($0, self.checkForCall(with: $0.user).hasActiveCall) }
        var callInfoToReturn: (info: [AnyHashable : Any]?, user: String)? = nil
        
        for callInfo in result {
            if let isActiveCall = callInfo.1, isActiveCall {
                callInfoToReturn = callInfo.0
                break
            }
        }
        
        return callInfoToReturn
    }
    
    var notifications: [[AnyHashable : Any]] {
        get {
            guard let defaults = self.defaults else { return [] }

            let keys = defaults.dictionaryRepresentation().keys.map{ $0 }
            let users = keys.filter{ $0.contains(callInfoPrefix) }.map{ $0.replacingOccurrences(of: "_" + callInfoPrefix, with: "") }

            return users.compactMap{ self.checkForCall(with: $0).info }
        }
    }
    
    func removeAll() {
        guard let defaults = self.defaults else { return }
        
        let keys = defaults.dictionaryRepresentation().keys.map{ $0 }
        let users = keys.filter{ $0.contains(callInfoPrefix) }.map{ $0.replacingOccurrences(of: "_" + callInfoPrefix, with: "") }
        
        users.forEach{ user in
            self.removeCallInfo(for: user)
        }
    }
    
    func removeCallInfo(for user: String) {
        guard let defaults = self.defaults else { return }
        
        let callInfoKey = user + "_" + callInfoPrefix
        let callStateKey = user + "_" + callStatePrefix
        
        defaults.removeObject(forKey: callInfoKey)
        defaults.removeObject(forKey: callStateKey)
    }
    
    typealias CallInfo = (info: [AnyHashable : Any]?, hasActiveCall: Bool?)
    func checkForCall(with user: String) -> CallInfo {
        guard let defaults = self.defaults else {
            return (nil, false)
        }
        
        let callInfoKey = user + "_" + callInfoPrefix
        let callStateKey = user + "_" + callStatePrefix
        
        
        let hasActiveCall = defaults.value(forKey: callStateKey) as? Bool
        let info = defaults.value(forKey: callInfoKey) as? [AnyHashable : Any]
        
        return (info, hasActiveCall)
    }
    
    func set(call info: [AnyHashable : Any], for user: String) {
        guard let defaults = self.defaults else { return }

        let callInfoKey = user + "_" + callInfoPrefix
        let callStateKey = user + "_" + callStatePrefix
        
        defaults.set(info, forKey: callInfoKey)
        defaults.set(true, forKey: callStateKey)
        
        defaults.synchronize()
    }
    
    func setEndCallFor(_ user: String) {
        guard let defaults = self.defaults else { return }
        
        let callStateKey = user + "_" + callStatePrefix
        defaults.set(false, forKey: callStateKey)
    }
}
