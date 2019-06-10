//
//  ExpertDirectionCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 1/31/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit 
import Kingfisher

class ExpertDirectionCell: UICollectionViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var previewImageView: UIImageView!
    
    private let selectedTitleColor = textColor3
    private let unselectedTitleColor = UIColor.white
    
    override var isSelected: Bool {
        didSet {
            self.update(with: isSelected)
        }
    }
    
    var skill: ExpertSkill! {
        didSet {
            self.update(with: skill)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.titleLabel.font = Font.light.of(size: 12)
        self.previewImageView.tintColor = self.unselectedTitleColor
        
        self.adjustConstraints()
    }

    private func update(with skill: ExpertSkill) {
        self.titleLabel.text = skill.title
    }
    
    private func update(with selectedState: Bool) {
        var skillImage: String = ""
        if selectedState {
            self.contentView.backgroundColor = selectedColor
            self.titleLabel.textColor = self.selectedTitleColor 
            skillImage = self.skill.selectedImage
        } else {
            self.contentView.backgroundColor = disabledColor
            self.titleLabel.textColor = self.unselectedTitleColor
            skillImage = self.skill.defaultImage
        }
        
        self.previewImageView.setImage(skillImage)
    }
}
