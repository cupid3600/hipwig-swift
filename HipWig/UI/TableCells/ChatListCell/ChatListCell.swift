//
//  ChatListCell.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class ChatListCell: MGSwipeTableCell {

    @IBOutlet private var avatar: UIImageView!
    @IBOutlet private var username: UILabel!
    @IBOutlet private var lastMessage: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var unreadCounterLabel: UILabel!
    @IBOutlet private var unreadCounterView: UIView!
    @IBOutlet private var unreadCounterWidth: NSLayoutConstraint!
    @IBOutlet private var blockedIcon: UIImageView!
    @IBOutlet private var blockedContainer: UIView!
    @IBOutlet private var avatarShadowView: UIView!
    @IBOutlet private var unblockLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.avatar.layer.cornerRadius = 12.adjusted
        self.avatar.layer.shouldRasterize = true
        self.avatar.layer.rasterizationScale = UIScreen.main.scale
        self.avatar.layer.masksToBounds = true

        self.unreadCounterView.layer.cornerRadius = 12.adjusted
        self.avatarShadowView.alpha = 0
        self.avatarShadowView.layer.cornerRadius = 12.adjusted
        self.blockedIcon.image = UIImage(named: "chat_blocked_icon")?.withRenderingMode(.alwaysTemplate)
        
        self.adjustConstraints()
        
        self.username.font = Font.regular.of(size: 16)
        self.dateLabel.font = Font.regular.of(size: 12)
        self.unreadCounterLabel.font = Font.regular.of(size: 12)
        self.unblockLabel.font = Font.regular.of(size: 12)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.imageView?.image = nil
        self.username.text = nil
        self.lastMessage.text = nil

        self.clearUnreadData()
        self.dateLabel.isHidden = false
        self.blockedContainer.isHidden = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }

    public func setup(chat: Conversation) {
        
        let user = chat.opponent
        self.avatar.setImage(user.profileImage)
        self.username.text = user.name

        if user.youBlocked || user.youWasBlocked {
            self.avatarShadowView.alpha = 0.7
            self.dateLabel.isHidden = true
            self.clearUnreadData() 
            return
        }
        
        self.avatarShadowView.alpha = 0
        self.blockedContainer.isHidden = true

        if chat.unreadCount == 0 {
            self.clearUnreadData()
        } else {
            self.unreadCounterLabel.text = "\(chat.unreadCount)"
            self.unreadCounterWidth.constant = 24.0.adjusted
            self.unreadCounterView.isHidden = false
        }

        guard let lastMessage = chat.lastMessage else {
            return
        }
        
        self.lastMessage.text = lastMessage.message
        self.dateLabel.text = DateFormatters.messageFormatter().string(from: lastMessage.createdAt)
    }

    private func clearUnreadData() {
        self.unreadCounterLabel.text = nil
        self.unreadCounterWidth.constant = 0.0
        self.unreadCounterView.isHidden = true
    }
}
