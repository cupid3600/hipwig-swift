//
//  Array+Safe.swift
//  Reinforce
//
//  Created by Vladyslav Shepitko on 3/13/19.
//  Copyright © 2019 Sonerim. All rights reserved.
//

import UIKit

extension Array {
    
    subscript(safe index: Int) -> Element? {
        if index >= 0 && index < self.count {
            return self[index]
        } else {
            return nil
        }
    }
}
