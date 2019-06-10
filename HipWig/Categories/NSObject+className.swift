//
//  NSObject+className.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension NSObject {
    
    class var className: String {
        return String(describing: self)
    }
    
}
