//
//  ChatTextCell.swift
//  HipWig
//
//  Created by Alexey on 1/24/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import ActiveLabel

class ChatTextCell: UITableViewCell {

    @IBOutlet weak var messageLabel: ActiveLabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageContainer: UIView!
    
    var cornerRadius: CGFloat = 15.0 {
        didSet {
            self.messageContainer.layer.cornerRadius = cornerRadius
        }
    }
    
    var urlSelectedClosure: (URL) -> Void = { _ in }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.adjustConstraints()
        
        self.dateLabel.font = Font.light.of(size: 12)
        self.messageLabel.font = Font.regular.of(size: 16)
        self.setup(messageLabel: self.messageLabel)
        self.cornerRadius = 15.0.adjusted
    }

    public func setup(with msg: ChatMessage) {
        self.messageLabel.text = msg.message
        self.dateLabel.text = DateFormatters.messageFormatter().string(from: msg.createdAt)
    }
    
    private func setup(messageLabel label: ActiveLabel) {
        label.enabledTypes = [.url]
        label.configureLinkAttribute = { type, attributes, value in
            var attributes = attributes
            
            switch type {
            case .url:
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                attributes[.foregroundColor] = UIColor(red: 52, green: 151, blue: 253)
            default:
                break
            }
            
            return attributes
        }
        
        label.customize { label in
            label.handleURLTap{ [weak self] url in
                guard let `self` = self else { return }
                
                self.urlSelectedClosure(url)
            }
        }
    }
}
