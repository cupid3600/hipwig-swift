//
//  Device+Adjust.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/6/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class Device {
    // Base width in point, use iPhone XS
    static let base: CGFloat = 414
    
    static var ratio: CGFloat {
        return UIScreen.main.bounds.width / base
    } 
}

extension CGFloat {
    
    var adjusted: CGFloat {
        return self * Device.ratio
    }
}

extension Double {
    
    var adjusted: CGFloat {
        return CGFloat(self) * Device.ratio
    }
}

extension Int {
    
    var adjusted: CGFloat {
        return CGFloat(self) * Device.ratio
    }
}
