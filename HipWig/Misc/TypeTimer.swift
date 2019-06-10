//
//  TypeTimer.swift
//  Reinforce
//
//  Created by Vladyslav Shepitko on 3/6/19.
//  Copyright © 2019 Sonerim. All rights reserved.
//

import UIKit

class TypeTimer {
    
    private var timer: Timer?
    
    func start(with completion: @escaping () -> Void) {
        self.stop()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            completion()
        }
    }
    
    private func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
}

class CountDownTimer {
    
    private var timer: Timer?
    private var interval: TimeInterval
    
    var intervalChangeClosure: (TimeInterval) -> Void = { _ in }
    var timeOutClosure: () -> Void = { }
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func start() {
        self.stop()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.interval -= 1
            
            if self.interval <= 0 {
                self.stop()
                self.timeOutClosure()
            } else {
                self.intervalChangeClosure(self.interval)
            }
        }
    }
    
    private func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
}
