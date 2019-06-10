//
//  UIButton+ApplyGradient.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

typealias GradientPoints = (startPoint: CGPoint, endPoint: CGPoint)

enum GradientOrientation {
    case topRightBottomLeft
    case topLeftBottomRight
    case horizontal
    case vertical
    case custom(CGPoint, CGPoint)
    
    var startPoint : CGPoint {
        return points.startPoint
    }
    
    var endPoint : CGPoint {
        return points.endPoint
    }
    
    var points : GradientPoints {
        switch self {
        case .topRightBottomLeft:
            return (CGPoint(x: 0.0,y: 1.0), CGPoint(x: 1.0,y: 0.0))
        case .topLeftBottomRight:
            return (CGPoint(x: 0.0,y: 0.0), CGPoint(x: 1,y: 1))
        case .horizontal:
            return (CGPoint(x: 0.0,y: 0.5), CGPoint(x: 1.0,y: 0.5))
        case .vertical:
            return (CGPoint(x: 0.0,y: 0.0), CGPoint(x: 0.0,y: 1.0))
        case .custom(let start, let finish):
            return (start, finish)
        }
    }
}

private var gradientObjectHandle: UInt8 = 0
extension UIView {
    
    // Declare a global var to produce a unique address as the assoc object handle
    
    
    private var gradient: CAGradientLayer? {
        get {
            return objc_getAssociatedObject(self, &gradientObjectHandle) as? CAGradientLayer
        }
        set {
            objc_setAssociatedObject(self, &gradientObjectHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func applyGradient(with colours: [UIColor], locations: [NSNumber]? = nil) {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func applyGradient(with colours: [UIColor], gradient orientation: GradientOrientation) {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.startPoint = orientation.startPoint
        gradient.endPoint = orientation.endPoint
        
        if self.gradient != nil {
            self.gradient?.removeFromSuperlayer()
            self.gradient = nil
        }
        
        self.gradient = gradient
        self.layer.insertSublayer(gradient, at: 0)
    }
}
