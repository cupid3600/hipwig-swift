//
//  ChatReceiveMessageCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/22/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ChatReceiveMessageCell: ChatTextCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.messageLabel.textColor = .white
        self.messageContainer.backgroundColor = disabledColor
    }
    
}
