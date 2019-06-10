//
//  UIView+shadow.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 28.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UIView {
    
    func addShadow(color: UIColor = .black, opacity: Float = 0.3, width: CGFloat = -1, height: CGFloat = 1, radus: CGFloat = 15) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = CGSize(width: width, height: height)
        self.layer.shadowRadius = radus
    }
}
