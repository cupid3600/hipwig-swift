//
//  LittleOptionSegment.swift
//  HipWig
//
//  Created by Alexey on 1/19/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation
import UIKit

protocol LittleOptionSegmentDelegate: class {
    func segmentView(_ segmentView: LittleOptionSegment, didSelectItemWithIndex index: Int)
    func segmentView(_ segmentView: LittleOptionSegment, didDeselectItemWithIndex index: Int)
}

class LittleOptionSegment: SegmenView {

    private var selectedOptions: [Int] = []
    weak var optionViewDelegate: LittleOptionSegmentDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.delegate = self
        self.contentInset = .zero
        self.itemSpacing = 22.0.adjusted
        self.allowToggle = true
    }
    
    override func reloadSegments() {
        super.reloadSegments()
        self.selectedOptions.removeAll()
    }
}

//MARK: - SegmentViewDelegate
extension LittleOptionSegment: SegmentViewDelegate {
    
    func segmentView(_ segmentView: SegmenView, shouldSelectSegmentWithIndex index: Int) -> Bool {
        return true
    }
    
    func segmentView(_ segmentView: SegmenView, didSelectSegmentWithIndex index: Int) {
        
        if let indexToRemove = self.selectedOptions.firstIndex(where: { $0 == index }) {
            self.deselectSegment(indexToRemove)
            
            self.selectedOptions.remove(at: indexToRemove)
            self.optionViewDelegate?.segmentView(self, didDeselectItemWithIndex: index)
        } else {
            self.selectedOptions.removeAll()
            self.selectedOptions.append(index)
            
            self.optionViewDelegate?.segmentView(self, didSelectItemWithIndex: index)
        }
    }
    
    func segmentView(_ segmentView: SegmenView, configureSegment segment: Segment) {
        segment.clipsToBounds = true
        segment.layer.cornerRadius = 8.0.adjusted
    }
}
