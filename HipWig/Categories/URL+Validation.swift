//
//  URL+Validation.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/18/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension URL {
    
    var isValidURL: Bool {
        let string = self.absoluteString
        
        let types: NSTextCheckingResult.CheckingType = [.link]
        let detector = try? NSDataDetector(types: types.rawValue)
        guard (detector != nil && string.count > 0) else { return false }
        if detector!.numberOfMatches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, string.count)) > 0 {
            return true
        }
        
        return false
    }
}
