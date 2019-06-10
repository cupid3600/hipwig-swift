//
//  AcceptedCallReceiveCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/27/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class AcceptedCallReceiveCell: ChatSystemCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.detailsLabel.textColor = textColor2
    }
    
}
