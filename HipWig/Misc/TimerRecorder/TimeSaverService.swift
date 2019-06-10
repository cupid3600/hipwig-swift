//
//  Some.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/19/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol TimeSaverService: class {
    func set(expertId: String)
    func updateCallTime()
}

private let kFinishTimerInterval: TimeInterval = 10.0
private let workQueue = DispatchQueue(label: "com.TimeRecordService.workQueue", qos: .userInteractive, attributes: .concurrent)

class TimeSaverServiceImplementation: TimeSaverService {
    
    private var expertId = ""
    
    private let account = AccountManager.manager
    private var api = RequestsManager.manager
    private let timeRecorder: TimeRecordService
    private var sendTimeStack: [TimeInterval] = []
    private let category = ExpertDetailsFeatureFlagCategoryImplementation.default
    
    init(timeRecorder: TimeRecordService) {
        self.timeRecorder = timeRecorder
        
        reachability.add(reachabylityDelegate: self)
    }
    
    deinit {
        reachability.remove(reachabylityDelegate: self)
        print(#file + " " + #function)
    }
    
    func set(expertId id: String) {
        self.expertId = id
    }
    
    func updateCallTime() {
        if !self.account.needSendTime || self.category.freeMinutes {
            return
        }
        
        print("[timer] start updating timer data on server")
        
        let prevSentTimeSum = self.sendTimeStack.reduce(0, +)
        let timeToSend = self.timeRecorder.callSpandTime - prevSentTimeSum
        
        self.sendTimeStack.append(timeToSend)
        
        if timeToSend > 0.0 {
            self.api.sendSpendedTime(timeInterval: timeToSend, expert: self.expertId) { error in
                if error != nil {
                    print("[timer] current timer NOT updated")
                } else {
                    UserDefaults.shouldUpdateTime = nil
                    print("[timer] current timer on server has been updated")
                }
            }
        }
    }
    
}

extension TimeSaverServiceImplementation:  NetworkReachabilityDelegate {
    
    func service(_ service: ReachabilityService, didChangeNetworkState isNetworkReachable: Bool) {
        if isNetworkReachable {
            if let shouldUpdateTime = UserDefaults.shouldUpdateTime, shouldUpdateTime {
                self.updateCallTime()
            }
            
        } else {
            UserDefaults.shouldUpdateTime = true
        }
    }
}

private let kCallEndedKey = "kCallEndedKey"
extension UserDefaults {
    
    class var shouldUpdateTime: Bool? {
        get {
            return UserDefaults.standard.value(forKey: kCallEndedKey) as? Bool
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kCallEndedKey)
            UserDefaults.standard.synchronize()
        }
    }
}

