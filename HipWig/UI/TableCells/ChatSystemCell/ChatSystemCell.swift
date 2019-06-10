//
//  ChatSystemCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/18/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ChatSystemCell: UITableViewCell {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.adjustConstraints()
        
        self.dateLabel.textColor = textColor2
        self.dateLabel.font = Font.light.of(size: 12)
        self.detailsLabel.font = Font.regular.of(size: 12)
    }
    
    func setup(with message: ChatMessage) {
        self.detailsLabel.text = message.message
        self.dateLabel.text = DateFormatters.messageFormatter().string(from: message.createdAt)
    }
}
