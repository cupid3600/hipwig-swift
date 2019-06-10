//
//  URL+DeepLink.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/9/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

typealias Route = (view: String, parameters:[String: String])
extension URL {
    
    func route(with appidentifier: String) -> Route? {
        if let scheme = self.scheme,
        scheme.localizedCaseInsensitiveCompare(appidentifier) == .orderedSame,
        let view = self.host {

            var parameters: [String: String] = [:]
            URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
                parameters[$0.name] = $0.value
            }
 
            return (view: view, parameters: parameters)
        } else {
            return nil
        }
    }
    
    func route() -> Route {
        
        let view = self.lastPathComponent
        var parameters: [String: String] = [:]
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
            parameters[$0.name] = $0.value
        }
        
        return (view: view, parameters: parameters)
    }
}
