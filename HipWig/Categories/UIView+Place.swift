//
//  UIView+Place.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UIView {
    
    func place(_ view: UIView, insets: UIEdgeInsets = .zero) {
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top).isActive = true
        view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: insets.left).isActive = true
        view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -insets.right).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom).isActive = true
    } 
}

