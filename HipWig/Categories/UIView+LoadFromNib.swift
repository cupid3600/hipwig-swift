//
//  UIView+LoadFromNib.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

public func instancetype<T>(object: Any?) -> T? {
    return object as? T
}

extension UIView {
    
    static var reuseIdentifier: String {
        return self.className
    }
    
    static var nib: UINib {
        return UINib(nibName: self.className, bundle: nil)
    }
    
    class func fromXib(_ name: String? = nil) -> Self? {
        return instancetype(object: Bundle.main.loadNibNamed(name ?? self.className, owner: nil, options: nil)?.last)
    }
    
    class func fromXib(_ name: String? = nil, owner: AnyObject? = nil) -> UIView? {
        return Bundle.main.loadNibNamed(name ?? self.className, owner: owner, options: nil)?.last as? UIView
    }
    
}
