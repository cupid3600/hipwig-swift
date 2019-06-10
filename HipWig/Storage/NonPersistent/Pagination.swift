//
//  Pagination.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

struct Pagination: Codable {
    
    var totalCount: Int
    let limit: Int
    var offset: Int
    var isEmpty = false
    var isFetching: Bool = false
    
    static var `default`: Pagination {
        return Pagination(totalCount: 0, limit: 20, offset: 0, isEmpty: false, isFetching: false)
    }
    
    static func `default`(with limit: Int) -> Pagination {
        return Pagination(totalCount: 0, limit: limit, offset: 0, isEmpty: false, isFetching: false)
    }
    
    var itemsToFetch: Int {
        let leftMedias = self.totalCount - self.offset
        if leftMedias > self.limit {
            return self.limit
        } else {
            return leftMedias
        }
    }
    
    var hasNextPage: Bool {
        return self.offset < self.totalCount
    }
    
    mutating func calculateNextPage() {
        self.offset += self.itemsToFetch
    }
    
}

extension Pagination {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        var totalCount = 0
        do {
            totalCount = try container.decode(Int.self, forKey: .totalCount)
        } catch DecodingError.typeMismatch( _, _) {
            let temp = try container.decode(String.self, forKey: .totalCount)
            totalCount = Int(temp)!
        }
        
        var limit = 0
        do {
            limit = try container.decode(Int.self, forKey: .limit)
        } catch DecodingError.typeMismatch(_, _) {
            let temp = try container.decode(String.self, forKey: .limit)
            limit = Int(temp)!
        }
        
        var offset = 0
        do {
            offset = try container.decode(Int.self, forKey: .offset)
        } catch DecodingError.typeMismatch(_, _) {
            let temp = try container.decode(String.self, forKey: .offset)
            offset = Int(temp)!
        }
        
        self.init(totalCount: totalCount, limit: limit, offset: offset, isEmpty: false, isFetching: false)
    }
}

