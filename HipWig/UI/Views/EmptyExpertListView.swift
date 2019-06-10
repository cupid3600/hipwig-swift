//
//  EmptyExpertListView.swift
//  Reinforce
//
//  Created by Vladyslav Shepitko on 4/10/19.
//  Copyright © 2019 Sonerim. All rights reserved.
//

import UIKit

class EmptyExpertListView: UIView {
    
    @IBOutlet private var textLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.textLabel.font = self.textLabel.font.adjusted
    }
}
