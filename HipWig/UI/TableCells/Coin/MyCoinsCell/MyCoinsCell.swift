//
//  MyCoinsCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/29/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class MyCoinsCell: UITableViewCell {
    
    @IBOutlet private weak var myCoinsTitleLabel: UILabel!
    @IBOutlet private weak var myCoinsCounLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }

    private func onLoad() {
        self.myCoinsTitleLabel.font = Font.regular.of(size: 16)
        self.myCoinsCounLabel.font = Font.regular.of(size: 40)
        self.containerView.layer.cornerRadius = 8.0.adjusted
        
        self.adjustConstraints()
    }
    
}
