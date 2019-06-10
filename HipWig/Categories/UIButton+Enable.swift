//
//  UIButton+Enable.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/8/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UIControl {
    
    func enable() {
        self.isEnabled = true
        self.isUserInteractionEnabled = true
    }
    
    func disable() {
        self.isEnabled = false
        self.isUserInteractionEnabled = false
    }
}
