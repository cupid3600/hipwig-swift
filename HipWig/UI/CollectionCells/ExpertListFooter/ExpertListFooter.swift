//
//  ExpertListFooter.swift
//  HipWig
//
//  Created by Alexey on 1/19/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ExpertListFooter: UICollectionReusableView {

    @IBOutlet public var spinner: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    static public func identifier() -> String {
        return "ExpertListFooter"
    }
}
