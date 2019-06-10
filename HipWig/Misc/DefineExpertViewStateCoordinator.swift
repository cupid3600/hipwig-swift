//
//  DefineExpertViewStateCoordinator.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/11/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

enum DefineExpertViewState: Int, CaseIterable {
    case images
    case paypalEmail
    case directions
}

class DefineExpertViewStateCoordinator {
    
    private (set) var state: DefineExpertViewState = .images
    private (set) var prevState: DefineExpertViewState?
    
    func update(with state: DefineExpertViewState, forceReload: Bool = false, completion: (DefineExpertViewState?) -> Void) {
        var newState: DefineExpertViewState? = nil
        if self.prevState == nil || self.state != state || forceReload {
            self.prevState = self.state
            
            self.state = state
            newState = state
        }
        
        completion(newState)
    }
    
    func set(state: DefineExpertViewState) {
        self.state = state
        self.prevState = state
    }
}
