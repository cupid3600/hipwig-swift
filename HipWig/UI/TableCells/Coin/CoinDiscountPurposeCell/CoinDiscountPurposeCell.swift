//
//  CoinDiscountPurpose.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/29/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class CoinDiscountPurposeCell: UITableViewCell {

    @IBOutlet private weak var coinsCounLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var priceContainerView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var saveLabel: UILabel!
    @IBOutlet private weak var saveDiscountLabel: UILabel!
    @IBOutlet private weak var saveDiscountImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.coinsCounLabel.font = Font.bold.of(size: 20)
        self.timeLabel.font = Font.regular.of(size: 16)
        self.priceLabel.font = Font.regular.of(size: 20)
        self.descriptionLabel.font = Font.regular.of(size: 16)
        self.saveLabel.font = Font.regular.of(size: 11)
        self.saveDiscountLabel.font = Font.bold.of(size: 15)
        
        self.containerView.layer.cornerRadius = 8.0.adjusted
        self.containerView.layer.borderColor = UIColor(red: 255, green: 79, blue: 154).cgColor
        self.containerView.layer.borderWidth = 1.0.adjusted
        
        self.priceContainerView.layer.cornerRadius = 8.0.adjusted
        self.priceContainerView.backgroundColor = UIColor(red: 42, green: 46, blue: 67)

        self.adjustConstraints()
    }
}
