//
//  ExpertHeader.swift
//  HipWig
//
//  Created by Alexey on 1/24/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Alamofire

protocol ExpertHeaderDelegate: class {
    func callDidSelect(_ sender: UIButton)
}

class ExpertHeader: UIView {

    public weak var delegate: ExpertHeaderDelegate?

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var buttonLabel: UILabel!
    @IBOutlet private weak var avatar: UIImageView!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var callButtonBackgroundView: UIView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var indicatorLeftConstraint: NSLayoutConstraint!
    
    var callButtonEnabled: Bool = false {
        didSet {
            self.button?.isUserInteractionEnabled = callButtonEnabled
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                self.loadingIndicator?.startAnimating()
            } else {
                self.loadingIndicator?.stopAnimating()
            }
            
            UIView.animate(withDuration: 0.5) {
                self.indicatorLeftConstraint?.constant = self.isLoading ? 30.adjusted : 10.adjusted
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        if let viewFromXIB = ExpertHeader.fromXib(owner: self) {
            self.place(viewFromXIB)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.avatar.layer.cornerRadius = 4.0.adjusted
        self.avatar.layer.masksToBounds = true

        self.callButtonBackgroundView.layer.cornerRadius = 8.0.adjusted
        self.callButtonBackgroundView.layer.masksToBounds = true
        
        self.buttonLabel.textColor = textColor3
        self.buttonLabel.font = self.buttonLabel.font.adjusted
        self.nameLabel.font = self.nameLabel.font.adjusted
        
        self.isLoading = false
        self.updateCallButton(enabled: false)
        self.adjustConstraints()
    }

    public func setup(user: User) {
        self.nameLabel.text = user.name
        self.avatar.setImage(user.profileImage)
    }
    
    func updateCallButton(enabled: Bool) {
        let color = enabled ? selectedColor : disabledColor
        self.callButtonBackgroundView.backgroundColor = color
        
        if enabled {
            self.button.enable()
        } else {
            self.button.disable()
        }
    }

    @IBAction private func callButtonDidSelect(_ sender: UIButton) {
        self.delegate?.callDidSelect(sender)
    }
}
