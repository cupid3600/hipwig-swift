//
//  TimeRecordService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/27/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import MulticastDelegateSwift

protocol TimeRecordServiceDelegate: class {
    func service(_ service: TimeRecordService, didReachTimeThreshold threshold: CallThreshold)
    func service(_ service: TimeRecordService, didChangeTimeInterval interval: TimeInterval)
}
enum PauseTimerReason: Int {
    case callPause
    case callEnded
    case interaption
    case networkDisable
    case streamDestroy
    case unknown
}

protocol TimeRecordService: class {
    
    var hasAvailableTime: Bool { get }
    var callSpandTime: TimeInterval { get }
    var availableTime: TimeInterval { get }
    var pauseReason: PauseTimerReason? { get }
    
    func addDelegate(delegate: TimeRecordServiceDelegate)
    func removeDelegate(delegate: TimeRecordServiceDelegate)
    
    func prepare()
    func start()
    func pause(reason: PauseTimerReason)
    func resume()
    func destroy()
}

private let timerInterval: TimeInterval = 1.0
private let workQueue = DispatchQueue(label: "com.TimeRecordService.workQueue", qos: .userInteractive, attributes: .concurrent)

private let kCallTimeKey = "kCallTimeKey"

extension UserDefaults {
    
    class fileprivate var callSpandTime: TimeInterval {
        get {
            return UserDefaults.standard.value(forKey: kCallTimeKey) as? Double ?? 0.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kCallTimeKey)
            UserDefaults.standard.synchronize()
        }
    }
}

enum CallThreshold: TimeInterval {
    case min2 = 120
    case min1 = 60
    case sec30 = 30
    case zero = 0
    
    var title: String {
        switch self {
        case .min2:
            return "2 mins left"
        case .min1:
            return "1 min left"
        case .sec30:
            return "30 seconds left"
        case .zero:
            return "0 mins left"
        }
    }
}

class TimeRecordServiceImplementation: TimeRecordService {
    
    private var delegate = MulticastDelegate<TimeRecordServiceDelegate>()
    
    private var currentTime: TimeInterval = 0
    private var timer: RepeatingTimer?
    private var api = RequestsManager.manager
    private let account = AccountManager.manager
    private lazy var currentCallThreshold: CallThreshold = self.defaultThreadhold()
    
    var availableTime: TimeInterval {
        return self.account.availableTime
    }
    
    var hasAvailableTime: Bool {
        return self.account.hasAvailableTime
    }
    
    var callSpandTime: TimeInterval {
        return UserDefaults.callSpandTime
    }
    
    private var _pauseReason: PauseTimerReason?
    var pauseReason: PauseTimerReason? {
        return self._pauseReason
    }
    
    init() {
        self.timer = RepeatingTimer(timeInterval: timerInterval)
        reachability.add(reachabylityDelegate: self)
    }
    
    deinit {
        self.timer = nil
        print(#file + " " + #function)
    }
    
    func prepare() {
        self.currentCallThreshold = self.defaultThreadhold()
        self.timer?.eventHandler = { [weak self] in
            guard let `self` = self else { return }
            
            let leftTime = self.availableTime - self.currentTime
            UserDefaults.callSpandTime = self.currentTime
            
            print("[timer] leftTime: \(leftTime) threshold: \(self.currentCallThreshold)")
            
            if leftTime <= 0.0 {
                self.currentCallThreshold = .zero
                
                self.delegate |> { [weak self] delegate in
                    guard let `self` = self else { return }
                    
                    delegate.service(self, didReachTimeThreshold: self.currentCallThreshold)
                }
            } else {
                if leftTime == self.currentCallThreshold.rawValue {
                    print("[timer] reach threshold: \(self.currentCallThreshold)")
                    
                    self.delegate |> { [weak self] delegate in
                        guard let `self` = self else { return }
                        
                        delegate.service(self, didReachTimeThreshold: self.currentCallThreshold)
                    }
                    
                    self.currentCallThreshold = self.nextThreadhold(for: leftTime)
                }
                
                self.delegate |> { [weak self] delegate in
                    guard let `self` = self else { return }
                    delegate.service(self, didChangeTimeInterval: self.currentTime)
                }
                
                self.currentTime += 1
            }
        }
    }
    
    private func nextThreadhold(for value: TimeInterval) -> CallThreshold {
        if value == CallThreshold.zero.rawValue || value == CallThreshold.sec30.rawValue {
            return CallThreshold.zero
        } else if value == CallThreshold.min1.rawValue {
            return CallThreshold.sec30
        } else if value == CallThreshold.min2.rawValue {
            return CallThreshold.min1
        }
        
        return .min2
    }
    
    private func defaultThreadhold() -> CallThreshold {
        if self.availableTime > CallThreshold.min2.rawValue {
            return .min2
        } else if self.availableTime > CallThreshold.min1.rawValue {
            return .min1
        } else if self.availableTime > CallThreshold.sec30.rawValue {
            return .sec30
        } else if self.availableTime > CallThreshold.zero.rawValue {
            return .zero
        }
        
        return .min2
    }
    
    func addDelegate(delegate: TimeRecordServiceDelegate) {
        if !self.delegate.containsDelegate(delegate) {
            self.delegate.addDelegate(delegate)
        }
    }
    
    func removeDelegate(delegate: TimeRecordServiceDelegate) {
        self.delegate.removeDelegate(delegate)
    }
    
    func start() {
        self._pauseReason = nil
        self.currentTime = 0
        self.timer?.resume()
        
        print("[timer] timer has been started")
    }
    
    func pause(reason: PauseTimerReason) {
        self._pauseReason = reason
        self.timer?.suspend()
        print("[timer] timer was pause")
    }
    
    func resume() {
        self._pauseReason = nil
        self.timer?.resume()
        print("[timer] resume timer")
    }
    
    func destroy() {
        self._pauseReason = nil
        self.timer?.suspend()
        print("[timer] destroy timer")
    }
}

//MARK: - NetworkReachabilityDelegate
extension TimeRecordServiceImplementation : NetworkReachabilityDelegate  {
    
    func service(_ service: ReachabilityService, didChangeNetworkState isReachable: Bool) {
//        if self.account.role != .expert {
        if isReachable {
            print("[timer] resume after network lost")
            self.resume()
        } else {
            print("[timer] connection lost")
            self.pause(reason: .networkDisable)
        }
//        }
    }
}
