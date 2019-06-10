//
//  ProfileGradientView.swift
//  HipWig
//
//  Created by Alexey on 1/21/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ProfileGradientView: UIImageView {

    private var gradientLayer = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()

        self.layer.insertSublayer(self.gradientLayer, at: 0)

        self.gradientLayer.colors = [UIColor.clear.cgColor, textColor3.cgColor]
        self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.gradientLayer.frame = self.bounds
    }
}
