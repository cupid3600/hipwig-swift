//
//  ChatSendMessageCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/22/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ChatSendMessageCell: ChatTextCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.messageLabel.textColor = selectedColor
        self.messageContainer.backgroundColor = UIColor(red: 35, green: 38, blue: 65)
    }
}
