//
//  UIViewController+Animation.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/6/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showAnimate(with containerView: UIView) {
        containerView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        containerView.alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            containerView.alpha = 1.0
            containerView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }
    
    func removeAnimate(with containerView: UIView, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            containerView.alpha = 0.0
            containerView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: { [weak self] _ in
            self?.dismiss(animated: true) {
                completion?()
            }
        })
    }
}
