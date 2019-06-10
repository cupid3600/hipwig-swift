//
//  InstargamPreviewPhotoCollectionCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Alamofire
//import AlamofireImage

class InstargamPreviewPhotoCollectionCell: UICollectionViewCell {

    @IBOutlet private weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func update(with url: URL) {
        self.imageView.setImage(url.absoluteString)
//        Alamofire.request(url).responseImage { response in
//            if let image = response.result.value {
//                self.imageView.image = image
//            }
//        }
    }

}
