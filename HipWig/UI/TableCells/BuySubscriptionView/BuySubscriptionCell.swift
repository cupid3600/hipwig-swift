//
//  BuySubscriptionCell.swift
//  HipWig
//
//  Created by Alexey on 1/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class BuySubscriptionCell: UITableViewCell {

    @IBOutlet private var topTitle: UILabel!
    @IBOutlet private var button: UIButton!
    @IBOutlet private var discountTitle: UILabel!
    @IBOutlet private var discountView: UIView!

    var buySelectedClosure: (() -> Void)?
    
    var allowChoosingPlan: Bool = true {
        didSet {
            self.button.isEnabled = allowChoosingPlan
            self.button.backgroundColor = allowChoosingPlan ? selectedColor : disabledColor
            
            let textColor: UIColor = allowChoosingPlan ? kPeranoColor : .white
            self.button.setTitleColor(textColor, for: .normal)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.backgroundColor = textColor3
        
        self.button.layer.cornerRadius = 8.0
        self.button.backgroundColor = selectedColor
        self.button.setTitle("Choose plan", for: .normal)
        self.button.setTitleColor(kPeranoColor, for: .normal)
        
        self.setup(subscriptionTitleLabel: self.topTitle)
        self.adjustConstraints()
    }
    
    private func setup(subscriptionTitleLabel label: UILabel) {
        label.font = Font.light.of(size: 16)
        label.textColor = UIColor.white.withAlphaComponent(0.4)
    }

    public func setup(isBought: Bool, discount: String, topText: String) {
        self.topTitle.text = topText

        if let value = Double(discount) {
            self.discountView.isHidden = value == 0.0
        } else {
            self.discountView.isHidden = discount.isEmpty
        }
        
        self.discountTitle.text = discount
    }

    @IBAction private func planButtonDidPressed() {
        self.buySelectedClosure?()
    }
}
