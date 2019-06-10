//
//  Font.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/6/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit


enum Font: String {
    
    case regular = "OpenSans"
    case medium = "OpenSans-Semibold"
    case bold = "OpenSans-Bold"
    case light = "OpenSans-Light"
    
    func of(size: CGFloat) -> UIFont {
        return Font.font(name: self.rawValue, of: size.adjusted) ?? UIFont.systemFont(ofSize: size.adjusted)
    }
    
    private static func font(name: String, of size: CGFloat) -> UIFont? {
        return UIFont(name: name, size: size)
    }
}

extension UIFont {
    var adjusted: UIFont {
        return UIFont(name: self.fontName, size: self.pointSize.adjusted)!
    }
}
