//
//  ProfileExpertListCollectionCell.swift
//  HipWig
//
//  Created by Alexey on 1/22/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Alamofire
import Kingfisher

class ProfileExpertListCollectionCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    private var expertID = ""
    private var downloadImageTask: DownloadTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView.layer.cornerRadius = 12.0.adjusted
//        self.imageView.layer.shouldRasterize = true
//        self.imageView.layer.rasterizationScale = UIScreen.main.scale
        self.imageView.layer.masksToBounds = true
        self.adjustConstraints()
        
        self.clear()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.imageView.image = nil
        self.clear()
    } 

    static public var inactiveAlpha: CGFloat {
        return 0.35
    }

    public func setup(expert: User) {
        self.expertID = expert.id
        self.downloadImageTask = self.imageView.setImage(expert.profileImage, placeholder: "expert_placeholder")
    }

    public func getExpertID() -> String {
        return self.expertID
    }

    private func clear() {
        self.imageView.alpha = ProfileExpertListCollectionCell.inactiveAlpha
    }
}
