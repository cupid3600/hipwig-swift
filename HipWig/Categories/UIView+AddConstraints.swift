//
//  UIView+AddConstraints.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/6/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UIView {
    
    func callRecursively(level: Int = 0, _ body: (_ subview: UIView, _ level: Int) -> Void) {
        body(self, level)
        
        subviews.forEach { $0.callRecursively(level: level + 1, body) }
    }
    
    func adjustConstraints() {
        self.callRecursively { subview, level in
            for constraint in subview.constraints {
                if constraint.constant != 0 {
                    constraint.constant = constraint.constant.adjusted
                }
            }
        }
    }
}
