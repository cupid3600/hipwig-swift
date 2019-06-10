//
//  ManagedObject+Identifier.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/23/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import CoreData

extension NSManagedObject {
    
    class var identifier: String {
        return String(describing: self)
    }
}
