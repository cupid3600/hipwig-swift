//
//  FacebookButton.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 6/5/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class FacebookButton: LoginButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.icon = UIImage(named: "facebook-logo")
        self.title = "login.continue_with_facebook".localized
        self.backgroundColor = UIColor(red: 65, green: 94, blue: 174)
    }
}
