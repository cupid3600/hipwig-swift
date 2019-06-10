//
//  UIImageView+KFLoaing.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/26/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Kingfisher

extension UIImageView {
   
    @discardableResult
    func setImage(_ urlString: String, placeholder: String? = nil) -> DownloadTask? {
        if let url = URL(string: urlString) {
            let resource = ImageResource(downloadURL: url)
            let placeholderImage = placeholder != nil ? UIImage(named: placeholder!) : nil
            let options: KingfisherOptionsInfo = placeholder != nil ? [.transition(.fade(1))] : []
            
            return self.kf.setImage(with: resource, placeholder: placeholderImage, options: options)
        }
        
        return nil
    }
}
