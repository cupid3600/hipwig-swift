//
//  BlockedChatCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/15/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol BlockedChatCellDelegate: class {
    func unblockDidSelect()
}

class BlockedChatCell: UITableViewCell {

    //MARK: - Outlets -
    @IBOutlet weak var unblockButton: UIButton!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var blockedTextLabel: UILabel!
    
    //MARK: - Properties -
    weak var delegate: BlockedChatCellDelegate?
    
    //MARK: - Life Cycle -
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    //MARK: - Actions -
    @IBAction private func unblockDidSelect() {
        delegate?.unblockDidSelect()
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(unblockButton: self.unblockButton)
        self.setup(detailsLabel: self.detailsLabel, text: "chat.blocked_chat_awailable_to_unblock".localized)
        self.setup(blockedTextLabel: self.blockedTextLabel)
    }
    
    var unblockButtonEnabled: Bool = true {
        didSet {
            if unblockButtonEnabled {
                self.unblockButton.setTitleColor(kTextColor, for: .normal)
                self.unblockButton.backgroundColor = selectedColor
            } else {
                self.unblockButton.setTitleColor(textColor2, for: .normal)
                self.unblockButton.backgroundColor = disabledColor
            }
            
            self.unblockButton.isUserInteractionEnabled = unblockButtonEnabled
        }
    }
    
    var blockedByMe: Bool = true {
        didSet {
            if blockedByMe {
                self.setup(detailsLabel: self.detailsLabel, text: "chat.blocked_chat_awailable_to_unblock".localized)
            } else {
                self.setup(detailsLabel: self.detailsLabel, text: "chat.blocked_chat_unawailable_to_unblock".localized)
            }
        }
    }
    
    private func setup(unblockButton button: UIButton) {
        button.titleLabel?.font = Font.regular.of(size: 16)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.titleLabel?.textAlignment = .center
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: -14.0, bottom: 0.0, right: 0.0)
        button.tintColor = .white
        
        button.setTitleColor(kTextColor, for: .normal)
        button.setTitle("chat.unblock_chat".localized, for: .normal)
        button.backgroundColor = selectedColor
    }
    
    private func setup(detailsLabel label: UILabel, text: String) {
        label.textColor = .white
        label.font = Font.light.of(size: 16)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        
        label.attributedText = NSMutableAttributedString(string: text, attributes: [.paragraphStyle: paragraphStyle])
    }
    
    private func setup(blockedTextLabel label: UILabel) {
        label.textColor = textColor2
        label.font = Font.regular.of(size: 20)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        
        label.attributedText = NSMutableAttributedString(string: "chat.blocked_chat".localized, attributes: [.paragraphStyle: paragraphStyle])
    }
}
