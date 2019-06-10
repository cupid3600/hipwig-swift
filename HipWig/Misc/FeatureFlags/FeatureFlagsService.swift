//
//  FeatureFlagsServiceImplementation.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/7/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Alamofire

protocol FeatureFlagCategory: class { 
}

extension FeatureFlagCategory {
    func value(for flag: FeatureFlag) -> Any? {
        switch flag.value {
        case .boolean(let val):
            return val
        case .int(let val):
            return val
        default:
            return nil
        }
    }
}

protocol FeatureFlagsService: class {
    func fetchFlags(completion: @escaping ErrorHandler)
}

class FeatureFlagsServiceImplementation: NSObject, FeatureFlagsService {

    private let api = RequestsManager.manager
    private var featureFlags: [FeatureFlag] = []
    private var pagination = Pagination.default(with: 500)
    private let workQueue = DispatchQueue(label: "com.FeatureFlagsServiceImplementation.workQueue", qos: .userInitiated, attributes: .concurrent)
    private var pages: [FeatureFlag] = []
    
    class var `defaut`: FeatureFlagsServiceImplementation {
        struct Wrapper {
            static let instance = FeatureFlagsServiceImplementation()
        }
        
        return Wrapper.instance
    }
    
    func fetchFlags(completion: @escaping ErrorHandler) {
        self.api.fetchFeatureFlags(self.pagination, categoryId: nil) { result in
            self.workQueue.async {
                var responseError: Error? = nil
                
                switch result {
                case .success(let data):
                    self.pages = data.rows
                case .failure(let error):
                    responseError = error
                }
                
                DispatchQueue.main.async {
                    completion(responseError)
                }
            }
        }
    }
}

protocol FeatureFlagServiceResponse: class {
    func flag(key: String) -> FeatureFlag?
}

extension FeatureFlagsServiceImplementation : FeatureFlagServiceResponse {
    
    func flag(key: String) -> FeatureFlag? {
        var flag: FeatureFlag? = nil
        self.workQueue.sync {
            if let index = self.pages.firstIndex(where: { $0.key == key }) {
                flag = self.pages[index]
            }
        }
        
        return flag
    }
}
