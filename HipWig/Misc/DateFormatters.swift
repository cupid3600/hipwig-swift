//
//  DateFormatters.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

class DateFormatters {
    static private let msgFormatter = DateFormatter()
    static private let defFormatter = DateFormatter()
    static private let subFormatter = DateFormatter()

    public static func messageFormatter() -> DateFormatter {
        msgFormatter.dateFormat = "HH:mm"
        msgFormatter.locale = Locale.current
        return msgFormatter
    }

    public static func defaultFormatter() -> DateFormatter {
        defFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        defFormatter.timeZone = TimeZone(abbreviation: "GMT")
        defFormatter.locale = Locale.current
        return defFormatter
    }

    public static func subscriptionFormatter() -> DateFormatter {
        subFormatter.dateFormat = "HH:mm dd-MM-yyyy"
        subFormatter.timeZone = TimeZone(abbreviation: "GMT")
        subFormatter.locale = Locale.current
        return subFormatter
    }
}
