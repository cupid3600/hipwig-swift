//
//  LoginButton.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 6/5/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class LoginButton: UIView {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var button: UIButton!
    
    var title: String? {
        didSet {
            self.titleLabel?.text = title
        }
    }
    
    var icon: UIImage? {
        didSet {
            self.iconImageView?.image = icon
        }
    }
    
    var textColor: UIColor = .white {
        didSet {
            self.titleLabel?.textColor = textColor
        }
    }
    
    var selectedClosure: (UIButton) -> Void = { _ in }
    
    override var tintColor: UIColor! {
        didSet {
            self.iconImageView?.tintColor = tintColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if let viewFromXIB = LoginButton.fromXib(owner: self) {
            self.place(viewFromXIB)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.clipsToBounds = true
        self.titleLabel?.font = Font.regular.of(size: 14)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.frame.height / 2.0
        self.titleLabel?.sizeToFit()
    }
    
    func disable() {
        self.button?.disable()
    }
    
    func enable() {
        self.button?.enable()
    }
    
    @IBAction private func selected(_ sender: UIButton) {
        self.selectedClosure(sender)
    }
}
