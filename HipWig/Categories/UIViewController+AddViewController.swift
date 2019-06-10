
//
//  UIViewController+AddViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func place(viewController: UIViewController, on containerView: UIView) {
        self.addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(viewController.view)

        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])

        viewController.didMove(toParent: self)
    }
    
    func dissmiss() {
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
}
