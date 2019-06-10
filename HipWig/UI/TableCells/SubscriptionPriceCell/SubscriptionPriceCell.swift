//
//  SubscriptionPriceCell.swift
//  HipWig
//
//  Created by Alexey on 1/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class SubscriptionPriceCell: UITableViewCell {

    @IBOutlet public var subscriptionTitleLabel: UILabel!
    @IBOutlet public var subscriptionPriceLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.adjustConstraints()
    }
    
    
}
