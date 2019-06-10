//
//  GoogleButton.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 6/5/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class GoogleButton: LoginButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.icon = UIImage(named: "g_logo")?.withRenderingMode(.alwaysOriginal)
        self.title = "login.continue_with_google".localized
        self.backgroundColor = .white
        self.textColor = UIColor(red: 62, green: 46, blue: 67)
    }
}
