//
//  LoginResponse.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

struct LoginResponse: Codable {
    let profile: User
    let refreshToken: String
    let accessToken: String
}

