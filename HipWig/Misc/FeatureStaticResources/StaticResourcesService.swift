//
//  StaticResourcesService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/20/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol StaticResourcesService: class {
    func fetchResourcesList(_ completion: @escaping () -> Void)
}

protocol StaticResourceCategory: class {
    var categoryKey: String { get }
}

final class StaticResourcesServiceImplementation: NSObject, StaticResourcesService {
    
    class var `defaut`: StaticResourcesServiceImplementation {
        struct Wrapper {
            static let instance = StaticResourcesServiceImplementation()
        }
        
        return Wrapper.instance
    }
    
    private let requestManager = RequestsManager.manager
    private var pagination: Pagination = .default(with: 100)
    
    private var resources: [StaticResource] = []
    
    private let workQueue = DispatchQueue(label: "com.staticResource.queue", qos: .userInteractive, attributes: .concurrent)
    
    private override init() {
        super.init()
    }
    
    func fetchResourcesList(_ completion: @escaping () -> Void) {
        self.requestManager.fetchStaticResources(pagination) { result in
            self.workQueue.async {
                switch result {
                case .success(let data):
                    self.resources = data.rows
                    
                case .failure(let error):
                    logger.log(error)
                }
                
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

}

protocol StaticResourcesServiceResponse: class {
    func value(for category: String, with key: String) -> String?
}

extension StaticResourcesServiceImplementation : StaticResourcesServiceResponse {
    
    func value(for category: String, with key: String) -> String? {
        var result: String? = .none
        self.workQueue.sync {
            if let index = self.resources.firstIndex(where: { $0.key == key }) {
                result = self.resources[index].file
            }
        }
        
        return result
    }
    
}

