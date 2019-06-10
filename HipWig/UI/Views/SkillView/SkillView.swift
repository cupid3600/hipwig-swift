//
//  SkillView.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/2/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class SkillView: UIView {

    @IBOutlet private weak var skillNameLabel: UILabel!
    @IBOutlet private weak var skillIconImageView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if let viewFromXIB = SkillView.fromXib(owner: self) {
            viewFromXIB.translatesAutoresizingMaskIntoConstraints = false
            self.place(viewFromXIB)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    } 
    
    private func onLoad() {
        self.skillNameLabel.font = Font.light.of(size: 12)
        let color = disabledColor
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        self.backgroundColor = color
    }
    
    func update(skillName: String, skillIcon: String) {
        self.skillNameLabel.text = skillName
        self.skillIconImageView.setImage(skillIcon)
    }
}
