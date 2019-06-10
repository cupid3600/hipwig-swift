//
//  CallCreditCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/5/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class CallCreditCell: UICollectionViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var popularityLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var savePercentsView: UIView!
    @IBOutlet private weak var savePercentsLabel: UILabel!
    @IBOutlet private weak var percentsLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            self.updateSelection(isSelected: isSelected)
        }
    }
    
    var product: Product? {
        didSet {
            self.update(with: product)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.setup(timeLabel: self.timeLabel)
        self.setup(popularityLabel: self.popularityLabel)
        self.setup(priceLabel: self.priceLabel)
        self.setup(savePercentsLabel: self.savePercentsLabel)
        self.setup(percentsLabel: self.percentsLabel)
        self.setup(containerView: self.containerView)
        self.setup(imageView: self.imageView)
        
        self.adjustConstraints()
        self.percentsLabel.text = "save"
    }
    
    private func setup(imageView: UIImageView) {
        imageView.image = UIImage(named: "save_credit_icon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor(red: 255, green: 79, blue: 154)
    }
    
    private func setup(timeLabel label: UILabel) {
        label.font = Font.bold.of(size: 18)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(popularityLabel label: UILabel) {
        label.font = Font.regular.of(size: 13)
        label.textAlignment = .center
        label.textColor = UIColor(red: 255, green: 79, blue: 154)
    }
    
    private func setup(priceLabel label: UILabel) {
        label.font = Font.regular.of(size: 18)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(savePercentsLabel label: UILabel) {
        label.font = Font.regular.of(size: 13)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(percentsLabel label: UILabel) {
        label.font = Font.bold.of(size: 18)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(containerView view: UIView) {
        view.addShadow()
        self.updateSelection(isSelected: false)
        view.layer.cornerRadius = 8
        view.layer.borderColor = UIColor(red: 255, green: 79, blue: 154).cgColor
    }
    
    private func updateSelection(isSelected: Bool) {
        self.containerView.layer.borderWidth = isSelected ? 1 : 0
    }
    
    func update(with product: Product?) {
        guard let product = self.product else {
            return
        }
        
        self.timeLabel.text = product.title
        self.priceLabel.text = product.price
        self.popularityLabel.text = product.centerText
        
        if product.discount.isEmpty || product.discount == "-" {
            self.savePercentsView.isHidden = true
        } else {
            self.savePercentsView.isHidden = false
            self.percentsLabel.text = product.discount
        }
    } 
}
