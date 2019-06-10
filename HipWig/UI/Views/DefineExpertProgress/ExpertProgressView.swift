//
//  ExpertProgressView.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/5/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ExpertProgressView: SegmenView {

    override var titles: [String] {
        didSet {
            self.reloadMarkedSegmets()
        }
    }
    
    private var makerdSegments: [Int] = []
    
    private lazy var checkMarkImage: UIImage? = {
        return UIImage(named: "segment_contol_selected")
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        onLoad()
    }
    
    private func onLoad() {
        changeSegmentStateHandler = { [weak self] segment, index in
            guard let `self` = self else { return }
            
            if self.makerdSegments.contains(index) {
                segment.setImage(self.checkMarkImage, for: .normal)
            } else {
                segment.setImage(nil, for: .normal)
            }
        }
    }
    
    func setSegmentAsMarked(with index: Int, condition: Bool) {
        if condition {
            if !self.makerdSegments.contains(index) {
                self.makerdSegments.append(index)
            }
        } else {
            if let indexToRemove = self.makerdSegments.firstIndex(where: { $0 == index }) {
                self.makerdSegments.remove(at: indexToRemove)
            }
        }
        
        self.reloadMarkedSegmets()
    }
    
    private func reloadMarkedSegmets() {
        for (index, segment) in self.segments.enumerated() {
            if makerdSegments.contains(index) {
                segment.setImage(self.checkMarkImage, for: .normal)
            } else {
                segment.setImage(nil, for: .normal)
            }
        }
    }
}
