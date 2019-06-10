//
//  ProfileCommentCollectionCell.swift
//  HipWig
//
//  Created by Alexey on 1/22/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ProfileCommentCollectionCell: UICollectionViewCell {

    @IBOutlet public var textLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.textLabel.font = Font.regular.of(size: 12)
        self.adjustConstraints()
    }
}
