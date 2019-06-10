//
//  Page.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/13/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

struct PageListResponse: Codable {
    let rows: [Page]
    let pagination: Pagination
}

struct Page: Codable {
    let id: String
    let name: String
}

enum PageKey: String {
    case some = ""
}
