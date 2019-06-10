//
//  StreamControlButton.swift
//  HipWig
//
//  Created by Alexey on 2/4/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class StreamControlButton: UIButton {

    @IBInspectable public var normalBackgroundColor: UIColor = .blue
    @IBInspectable public var selectedBackgroundColor: UIColor = .blue
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.backgroundColor = UIColor(red: 42, green: 46, blue: 67, alpha:0.4)
        self.layer.borderColor = UIColor(white: 1.0, alpha: 0.4).cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 12.0
    } 
}
