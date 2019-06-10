//
//  SegmenView.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 1/31/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

@objc protocol SegmentViewDelegate: class {
    func segmentView(_ segmentView: SegmenView, shouldSelectSegmentWithIndex index: Int) -> Bool
    func segmentView(_ segmentView: SegmenView, didSelectSegmentWithIndex index: Int)
    @objc optional func segmentView(_ segmentView: SegmenView, configureSegment segment: Segment)
}

typealias Segment = UIButton

@IBDesignable
class SegmenView: UIView {

    @IBInspectable public var containerBackgroundColor: UIColor = .white
    @IBInspectable public var selectedColor: UIColor = .black
    @IBInspectable public var unselectedColor: UIColor = .black
    @IBInspectable public var selectedTitleColor: UIColor = .white
    @IBInspectable public var unselectedTitleColor: UIColor = .white
    
    var contentInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    var itemSpacing: CGFloat = 1.0.adjusted
    var allowToggle: Bool = false
    var changeSegmentStateHandler: (Segment, Int) -> Void = { _, _ in }
    var deselectSegments: Bool = true
    private (set) var selectedIndex: Int = 0
    var titles: [String] = ["", "", ""] {
        didSet {
            self.reloadSegments()
        }
    }
    
    private (set) var segments: [UIButton] = []

    weak var delegate: SegmentViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.onLoad()
    }
    
    private func onLoad() {
        self.reloadSegments()
    }
    
    func reloadSegments() {
        self.cleanView()
        self.createViews()
    }
    
    private func createViews() {
        self.segments.removeAll()
        
        for (i, title) in self.titles.enumerated() {
            let segment = self.createSegment(with: i, title: title)
            
            self.delegate?.segmentView?(self, configureSegment: segment)
            self.segments.append(segment)
        }
        
        let stackView = UIStackView()
        stackView.spacing = self.itemSpacing
        
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        
        for segment in segments {
            stackView.addArrangedSubview(segment)
        }
        
        self.place(stackView, insets: contentInset)
        self.backgroundColor = self.containerBackgroundColor
    }
    
    private func createSegment(with index: Int, title: String) -> Segment {
        let segment = Segment(type: .custom)
        segment.addTarget(self, action: #selector(segmentDidSelect(_:)), for: .touchUpInside)
        segment.adjustsImageWhenHighlighted = false
        segment.tag = index
        segment.setTitle(title, for: .normal)
        segment.setTitleColor(self.selectedTitleColor, for: .selected)
        segment.setTitleColor(self.unselectedTitleColor, for: .normal)
        segment.titleLabel?.font = Font.regular.of(size: 13)
        segment.backgroundColor = self.unselectedColor
        segment.semanticContentAttribute = .forceRightToLeft
        segment.imageEdgeInsets = UIEdgeInsets(top: 0, left: 7.adjusted, bottom: 0, right: -7.adjusted)
        
        return segment
    }
    
    private func cleanView() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
    }
    
    func selectSegment(_ index: Int) {
        guard index >= 0 && index < self.titles.count else {
            return
        }
        
        self.handleSelection(with: index)
    }
    
    func deselectSegment(_ index: Int) {
        guard index >= 0 && index < self.titles.count else {
            return
        }
        
        let segment = self.segments[index]
        self.handleDeselection(for: segment, index: index)
    }
    
    @objc private func segmentDidSelect(_ sender: UIButton) {
        guard let delegate = self.delegate else {
            return
        }
        
        if self.allowToggle {
            if sender.isSelected {
                self.deselectSegment(sender.tag)
                self.delegate?.segmentView(self, didSelectSegmentWithIndex: sender.tag)
            } else {
                if delegate.segmentView(self, shouldSelectSegmentWithIndex: sender.tag) {
                    self.handleSelection(with: sender.tag)
                }
            }
        } else {
            if delegate.segmentView(self, shouldSelectSegmentWithIndex: sender.tag) {
                self.handleSelection(with: sender.tag)
            }
        }
    }

    private func handleSelection(with index: Int) {
        let segment = self.segments[index]
        segment.backgroundColor = self.selectedColor
        segment.isSelected = true
        
        self.selectedIndex = index
        self.changeSegmentStateHandler(segment, index)
        let restSegments = self.segments.filter { $0.tag != index }
        
        for (index, segment) in restSegments.enumerated() {
            self.handleDeselection(for: segment, index: index)
        }
        
        self.delegate?.segmentView(self, didSelectSegmentWithIndex: index)
    }
    
    private func handleDeselection(for segment: Segment, index: Int) {
        segment.isSelected = false
        segment.backgroundColor = self.unselectedColor
        segment.setImage(nil, for: .normal)
        
        changeSegmentStateHandler(segment, index)
    } 
}
