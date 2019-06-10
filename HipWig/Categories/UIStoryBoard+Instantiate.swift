//
//  UIStoryBoard+Instantiate.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UIStoryboard {
    
    class var nameReplaced: String {
        return self.className.replacingOccurrences(of: "Storyboard", with: "")
    }
    
    class var instance: UIStoryboard {
        return UIStoryboard(name: self.nameReplaced, bundle: nil)
    }
    
    func instantiate<T: UIViewController>(customID: String? = nil) -> T {
        return self.instantiateViewController(withIdentifier: customID ?? T.className) as! T
    }
    
    class func instantiate<T: UIViewController>(customID: String? = nil) -> T {
        return self.instance.instantiate(customID: customID) 
    }
}
