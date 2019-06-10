//
//  DeclinedCallSendCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/19/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class DeclinedCallSendCell: ChatSystemCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.detailsLabel.textColor = UIColor(red: 255, green: 79, blue: 79)
    }
}
