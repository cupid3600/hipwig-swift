//
//  UIButton+verticalAlignment.swift
//  HipWig
//
//  Created by Alexey on 1/17/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Foundation

extension UIButton {

    public func centerVertically(padding: CGFloat) {
        let imageSize = self.imageView!.frame.size
        let titleSize = self.titleLabel!.text!.size(withAttributes: [NSAttributedString.Key.font: self.titleLabel!.font])
        let totalHeight = (imageSize.height + titleSize.height + padding)

        self.imageEdgeInsets = UIEdgeInsets(top: -(totalHeight - imageSize.height), left: 0.0, bottom: 0.0, right: -titleSize.width)

        self.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: -imageSize.width, bottom: -(totalHeight - titleSize.height), right: 0.0)

    }

}
