//
//  NavigationBar.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/11/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.onLoad()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.onLoad()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    private func onLoad() {
        self.backgroundColor = .clear
        self.prefersLargeTitles = true
        self.isTranslucent = false
        self.barTintColor = textColor3
        self.setTitleVerticalPositionAdjustment(-20, for: .default)
        self.tintColor = .white

        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.white,
            NSAttributedString.Key.font : Font.regular.of(size: 24)
        ] 
    }
    
}
