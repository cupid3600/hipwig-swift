//
//  CoinCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/29/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class CoinCell: UITableViewCell {

    @IBOutlet private weak var discountLabel: UILabel!
    @IBOutlet private weak var coinsCounLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var priceContainerView: UIView!
    @IBOutlet private weak var hotLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    
    var isHot: Bool = false {
        didSet {
            self.priceContainerView?.layer.borderWidth = isHot ? 1.0.adjusted : 0.0
            self.priceContainerView?.layer.borderColor = isHot ? containerBorderColor : nil
            self.hotLabel?.isHidden = !isHot
        }
    }
    
    var hasDiscount: Bool = false {
        didSet {
            self.discountLabel?.isHidden = !hasDiscount
        }
    }
    
    private let hotPurposeColor = UIColor(red: 149, green: 157, blue: 173).cgColor
    private let containerBorderColor = UIColor(red: 255, green: 226, blue: 122).cgColor
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }

    private func onLoad() {
        self.coinsCounLabel.font = Font.bold.of(size: 20)
        self.discountLabel.font = Font.regular.of(size: 20)
        self.hotLabel.font = Font.bold.of(size: 14)
        self.priceLabel.font = Font.regular.of(size: 20)
        
        self.containerView.layer.cornerRadius = 8.0.adjusted
        self.containerView.layer.borderColor = UIColor(red: 149, green: 157, blue: 173).cgColor
        self.containerView.layer.borderWidth = 1.0.adjusted
        
        self.priceContainerView.layer.cornerRadius = 8.0.adjusted
        self.priceContainerView.backgroundColor = UIColor(red: 42, green: 46, blue: 67)
        
        self.isHot = false
        self.hasDiscount = false
        self.adjustConstraints()
    }
    
}
