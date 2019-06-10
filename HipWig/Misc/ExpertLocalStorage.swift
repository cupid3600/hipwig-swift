//
//  ExpertLocalStorage.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

typealias FetchExpertListResult = (experts: [User], pagination: Pagination)
typealias FetchMoreExpertListResult = (indexPaths: [IndexPath]?, pagination: Pagination)

protocol ExpertLocalStorage: class {
    
    var count: Int { get }
    var experts: [User] { get }
    subscript(index: Int) -> User { get }
    
    func clean()
    func fetchExperts(filter: ExpertsFilter, pagination: Pagination, completion: @escaping ValueHandler<FetchExpertListResult>)
    func fetchMoreExperts(filter: ExpertsFilter, pagination: Pagination, completion: @escaping ValueHandler<FetchMoreExpertListResult>)
}

class ExpertLocalStorageImplementation: ExpertLocalStorage {
    
    static let `default`: ExpertLocalStorageImplementation = ExpertLocalStorageImplementation()
    private let api: RequestsManager = RequestsManager.manager
    
    private (set) var experts: [User] = []
    
    private init() {
        
    }
    
    var count: Int {
        return self.experts.count
    }
    
    subscript(index: Int) -> User {
        get {
            return self.experts[index]
        }
    }
    
    func clean() {
        self.experts.removeAll()
    }
    
    func fetchExperts(filter: ExpertsFilter, pagination: Pagination, completion: @escaping ValueHandler<FetchExpertListResult>) {
        self.api.getExpertsList(filter: filter, pagination: pagination) { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let response):
                self.experts = response.rows
                let result = (experts: self.experts, pagination: response.pagination)
                
                completion(.success(result))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchMoreExperts(filter: ExpertsFilter, pagination: Pagination, completion: @escaping ValueHandler<FetchMoreExpertListResult>) {
        self.api.getExpertsList(filter: filter, pagination: pagination) { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let response):
                let prevCount = self.experts.count
                self.experts.append(contentsOf: response.rows)
                let newCount = self.experts.count

                var indexPaths: [IndexPath]? = nil

                if prevCount != newCount {
                    indexPaths = (prevCount ..< newCount).map { IndexPath(row: $0, section: 0) }
                }

                let result = (indexPaths: indexPaths, pagination: response.pagination)
                
                completion(.success(result))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
