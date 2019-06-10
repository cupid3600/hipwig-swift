//
//  SelectGenderView.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/4/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class SelectGenderView: LittleOptionSegment {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.updateTextLabels()
        NotificationCenter.addUpdateLocalizationObserver { [weak self] in
            guard let `self` = self else { return }
            self.updateTextLabels()
        }
    }
    
    private func updateTextLabels() {
        self.titles = Sex.allCases.map{ $0.title }
    }
}
