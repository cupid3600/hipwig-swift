//
//  Compare+Clamped.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 1/30/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension Comparable {
    func clamped(lowerBound: Self, upperBound: Self) -> Self {
        return min(max(self, lowerBound), upperBound)
    }
}
