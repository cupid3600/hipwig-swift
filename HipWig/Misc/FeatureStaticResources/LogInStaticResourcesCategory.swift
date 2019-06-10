//
//  LogInStaticResourcesCategory.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/20/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol LogInStaticResourcesCategory: StaticResourceCategory {
    var defaultIntroVideoURL: URL { get } 
    var introVideoURLInfo: (value: URL, isDefaultVideo: Bool) { get }
}

final class LogInStaticResourcesCategoryImplementation: LogInStaticResourcesCategory {
    
    static let `default`: LogInStaticResourcesCategoryImplementation = LogInStaticResourcesCategoryImplementation()
    
    var categoryKey: String {
        return "categoryKey"
    }
    
    private var response: StaticResourcesServiceResponse? {
        get {
            return staticResourcesService as? StaticResourcesServiceResponse
        }
    }
    
    private let staticResourcesService: StaticResourcesService = StaticResourcesServiceImplementation.defaut
    
    var defaultIntroVideoURL: URL {
        return NSURL.fileURL(withPath: Bundle.main.path(forResource: "intro", ofType: "mov")!)
    }
    
    var introVideoURLInfo: (value: URL, isDefaultVideo: Bool) {
        if let fileURLString = self.response?.value(for: categoryKey, with: "BECOME_EXPERT_VIDEO") {
            if let url = URL(string: fileURLString) {
               return (url, false)
            } else {
                return (self.defaultIntroVideoURL, true)
            }
        } else {
            return (self.defaultIntroVideoURL, true)
        }
    }
}
