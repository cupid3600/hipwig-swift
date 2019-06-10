//
//  SubscriptionInfoCell.swift
//  HipWig
//
//  Created by Alexey on 1/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class SubscriptionInfoCell: UITableViewCell {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var checkmarkImageView: UIImageView!
    @IBOutlet private var descriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.onload()
    }
    
    private func onload() {
        self.adjustConstraints()
        
        self.containerView.layer.cornerRadius = 8
        self.backgroundColor = textColor3
        self.containerView.backgroundColor = disabledColor
        self.setup(descriptionLabel: self.descriptionLabel)
    }
    
    private func setup(descriptionLabel label: UILabel) {
        label.font = UIFont(name: "OpenSans-Light", size: 16)
        label.textColor = .white
    }

    public func setup(text: String, isBought: Bool) {
        self.descriptionLabel.text = text
        self.checkmarkImageView.image = isBought ? nil : UIImage(named: "checkmark_icon")
    }
}
