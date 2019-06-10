
//
//  Timer.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/8/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class StartCallTimer {

    private var timer: Timer?
    
    func start(timeout: Double, timeOutCompletionClosure: @escaping () -> Void) {
        self.stop()
        self.timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { timer in
            timeOutCompletionClosure()
        }
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }

}

class RepeatTimer {
    
    private var timer: Timer?
    
    func start(interval: Double = 2.0, timeOutCompletionClosure: @escaping () -> Void) {
        self.stop()
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            timeOutCompletionClosure()
        }
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
}
