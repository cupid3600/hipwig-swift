//
//  Error+Network.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/29/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension Error {
    var isNetworkError: Bool {
        let error = self as NSError
        return error.code == NSURLErrorNetworkConnectionLost
            || error.code == NSURLErrorNotConnectedToInternet
            || error.code == NSURLErrorCannotConnectToHost
    }
}
