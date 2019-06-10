//
//  IncomingCallBannerView.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/18/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class IncomingCallBannerView: UIView {
    
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var userAvatarImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.userAvatarImageView.layer.cornerRadius = 4.0
        self.userAvatarImageView.layer.masksToBounds = true
        self.messageLabel.font = self.messageLabel.font.adjusted
        self.userNameLabel.font = self.userNameLabel.font.adjusted
    }
    
    func update(with user: User) {
        self.messageLabel.text = "Incoming call"
        self.userNameLabel.text = user.name
        self.userAvatarImageView.setImage(user.profileImage)
    }
    
}

