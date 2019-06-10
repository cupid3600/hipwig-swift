//
//  String+TimeInterval.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/24/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension TimeInterval {
    
    var timeValue: String {
        let hours = (self / 3600).rounded(.down)
        let minutes = (self.truncatingRemainder(dividingBy: 3600) / 60).rounded(.down)
        let seconds = (self.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)).rounded(.down)
        
        return String(format: "%0.f:%0.f:%0.f", hours, minutes, seconds)
    }
    
    var minutes: Int {
        return Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
    }
    
    var seconds: Int {
        return Int(self.truncatingRemainder(dividingBy: 60))
    }
}
