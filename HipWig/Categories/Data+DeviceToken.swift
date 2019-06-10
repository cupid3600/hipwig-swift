//
//  Data+DeviceToken.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/22/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension Data {
    
    var tokenValue: String {
        return self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
