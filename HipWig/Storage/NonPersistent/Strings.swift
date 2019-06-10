//
//  Strings.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/12/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

struct StringsListResponse: Codable {
    let rows: [FeatureStringValue]
    let pagination: Pagination
}


struct FeatureStringValue: Codable {
    let id: String
    let key: String
    let text: String
}
