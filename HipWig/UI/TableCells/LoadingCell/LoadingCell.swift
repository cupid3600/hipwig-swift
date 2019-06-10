//
//  LoadingCell.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class LoadingCell: UITableViewCell {

    @IBOutlet public var spinner: UIActivityIndicatorView!

    static public func identifier() -> String {
        return "LoadingCell"
    }
    
}
