//
//  InstargamButton.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Device_swift

class InstargamButton: LoginButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.icon = UIImage(named: "Instagram_2")?.withRenderingMode(.alwaysTemplate)
        self.title = "login.continue_with_instagram".localized
        self.tintColor = .white
    }
}
