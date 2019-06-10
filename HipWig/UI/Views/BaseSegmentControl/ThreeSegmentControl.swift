//
//  BaseSegmentControl.swift
//  HipWig
//
//  Created by Alexey on 1/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol ThreeSegmentControlDelegate: class {
    func onSegmentAction(index: Int)
}

class ThreeSegmentControl: UIView {

    @IBOutlet private var leftButton: UIButton?
    @IBOutlet private var centerButton: UIButton?
    @IBOutlet private var rightButton: UIButton?

    public var titles: [String] {
        willSet {
            self.leftButton?.setTitle(newValue[0], for: .normal)
            self.centerButton?.setTitle(newValue[1], for: .normal)
            self.rightButton?.setTitle(newValue[2], for: .normal)
        }
    }

    public weak var delegate: ThreeSegmentControlDelegate?

    public func selectSegment(index: Int) {
        self.unselectButtons()
        switch index {
        case 0:
            self.leftButton?.isSelected = true
            self.leftButton?.backgroundColor = selectedColor
        case 1:
            self.centerButton?.isSelected = true
            self.centerButton?.backgroundColor = selectedColor
        case 2:
            self.rightButton?.isSelected = true
            self.rightButton?.backgroundColor = selectedColor
        default:
            break
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.titles = ["", "", ""]
        super.init(coder: aDecoder)

        let view = Bundle.main.loadNibNamed("ThreeSegmentControl", owner: self, options: nil)?[0] as! UIView
        self.addSubview(view)
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction private func leftButtonDidPressed(sender: UIButton) {
        self.unselectButtons()
        self.leftButton?.isSelected = true
        self.leftButton?.backgroundColor = selectedColor

        self.delegate?.onSegmentAction(index: 0)
    }

    @IBAction private func centerButtonDidPressed(sender: UIButton) {
        self.unselectButtons()
        self.centerButton?.isSelected = true
        self.centerButton?.backgroundColor = selectedColor

        self.delegate?.onSegmentAction(index: 1)
    }

    @IBAction private func rightButtonDidPressed(sender: UIButton) {
        self.unselectButtons()
        self.rightButton?.isSelected = true
        self.rightButton?.backgroundColor = selectedColor

        self.delegate?.onSegmentAction(index: 2)
    }

    private func unselectButtons() {
        let unselectedColor = UIColor(red: 42, green: 45, blue: 66)
        
        self.centerButton?.isSelected = false
        self.centerButton?.backgroundColor = unselectedColor
        self.rightButton?.isSelected = false
        self.rightButton?.backgroundColor = unselectedColor
        self.leftButton?.isSelected = false
        self.leftButton?.backgroundColor = unselectedColor
    }
}
