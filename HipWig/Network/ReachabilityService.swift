
//
//  ReachabilityService.swift
//  Reinforce
//
//  Created by Vladyslav Shepitko on 5/7/19.
//  Copyright © 2019 Sonerim. All rights reserved.
//

import UIKit
import Reachability
import MulticastDelegateSwift

protocol NetworkReachabilityDelegate: class {
    func service(_ service: ReachabilityService, didChangeNetworkState isNetworkReachable: Bool)
}

protocol ReachabilityService: class {
    var isNetworkReachable: Bool { get }
    
    func addWhenReachable(_ handler: NSObject, completion: @escaping () -> Void)
    func removeWhenReachable(_ handler: NSObject)
    
    func add(reachabylityDelegate: NetworkReachabilityDelegate)
    func remove(reachabylityDelegate: NetworkReachabilityDelegate)
}

let reachability: ReachabilityService = ReachabilityServiceImplementation.default

class ReachabilityServiceImplementation: ReachabilityService {
    
    static let `default`: ReachabilityServiceImplementation = ReachabilityServiceImplementation()
    
    private let reachability = Reachability()!
    private let delegate = MulticastDelegate<NetworkReachabilityDelegate>()
    private var hanlers: [ReachabilityHandler] = []
    
    private init () {
        self.reachability.whenReachable = { [weak self] reachability in
            guard let `self` = self else { return }
            
            self.delegate |> { delegate in
                delegate.service(self, didChangeNetworkState: self.isNetworkReachable)
            }
        }
        
        self.reachability.whenUnreachable = { [weak self] reachability in
            guard let `self` = self else { return }
            
            self.delegate |> { delegate in
                delegate.service(self, didChangeNetworkState: self.isNetworkReachable)
            }
            
            ModalStoryboard.showUnavailableNetwork()
        }
        
        do {
            try self.reachability.startNotifier()
        } catch {
            
        }
    }
    
    func addWhenReachable(_ handler: NSObject, completion: @escaping () -> Void) {
        if !self.hanlers.contains(where: {$0.object === handler }) {
            let listenerWrapper = ReachabilityHandler(object: handler, action: completion)
            self.hanlers.append(listenerWrapper)
        }
    }
    
    func removeWhenReachable(_ handler: NSObject) {
        self.hanlers.removeAll(where: { $0.object === handler })
    }
    
    var isNetworkReachable: Bool {
        return self.reachability.connection != .none
    }
    
    func add(reachabylityDelegate: NetworkReachabilityDelegate) {
        self.delegate += reachabylityDelegate
    }
    
    func remove(reachabylityDelegate: NetworkReachabilityDelegate) {
        self.delegate -= reachabylityDelegate
    }
    
    private struct ReachabilityHandler {
        let object: NSObject
        let action: () -> Void
    }
}
