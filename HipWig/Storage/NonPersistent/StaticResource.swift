//
//  StaticResource.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/19/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

struct StaticResourceResponse: Codable {
    let pagination: Pagination
    let rows: [StaticResource]
}

struct StaticResource: Codable {
    let id: String
    let key: String
    let title: String
    let file: String
}
