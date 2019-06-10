//
//  UINavigationController+PushAnimation.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

public extension UINavigationController {
    
    /**
     Pop current view controller to previous view controller.
     
     - parameter type:     transition animation type.
     - parameter duration: transition animation duration.
     */
    func pop(transitionType type: CATransitionType = .moveIn, duration: CFTimeInterval = 0.3) {
        self.addTransition(transitionType: type, direction: .fromBottom, duration: duration)
        self.popViewController(animated: false)
    }
    
    /**
     Push a new view controller on the view controllers's stack.
     
     - parameter vc:       view controller to push.
     - parameter type:     transition animation type.
     - parameter duration: transition animation duration.
     */
    func push(viewController vc: UIViewController, transitionType type: CATransitionType = .moveIn, direction: CATransitionSubtype? = .fromTop, duration: CFTimeInterval = 0.2) {
        self.addTransition(transitionType: type, direction: direction, duration: duration)
        self.pushViewController(vc, animated: false)
    }
    
    private func addTransition(transitionType type: CATransitionType = .moveIn, direction: CATransitionSubtype? = .fromTop, duration: CFTimeInterval = 0.3) {
        let transition = CATransition()
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = type
        transition.subtype = direction
        
        self.view.layer.add(transition, forKey: nil)
    }
    
}
