//
//  BigOptionSegment.swift
//  HipWig
//
//  Created by Alexey on 1/17/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

enum OptionSegmentType {
    case none
    case purpose
    case sex
    case location
}

protocol BigOptionSegmentDelegate: class {
    func onSegmentAction(type: OptionSegmentType, value: String)
}

class BigOptionSegment: UIView {

    public var titles = ["", ""]
    public var values = ["", ""]
    public var normalIcons = ["", ""]
    public var selectedIcons = ["", ""]
    public var type: OptionSegmentType = .none

    public weak var delegate: BigOptionSegmentDelegate?

    @IBOutlet private var leftButton: UIButton!
    @IBOutlet private var rightButton: UIButton!

    private let selectedColor = UIColor(displayP3Red: 15.0/255.0, green: 244.0/255.0, blue: 195.0/255.0, alpha: 1.0)
    private let normalColor = UIColor(displayP3Red: 70.0/255.0, green: 75.0/255.0, blue: 97.0/255.0, alpha: 1.0)

    public func applyDefaultState() {
        self.leftButton.backgroundColor = self.normalColor
        self.rightButton.backgroundColor = self.normalColor
        self.leftButton.setImage(UIImage(named: self.normalIcons[0]), for: .normal)
        self.rightButton.setImage(UIImage(named: self.normalIcons[1]), for: .normal)
        self.leftButton.setTitle(self.titles[0], for: .normal)
        self.rightButton.setTitle(self.titles[1], for: .normal)

        self.leftButton.centerVertically(padding: 22.0)
        self.rightButton.centerVertically(padding: 22.0)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let view = Bundle.main.loadNibNamed("BigOptionSegment", owner: self, options: nil)?[0] as! UIView
        self.addSubview(view)
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.leftButton.layer.cornerRadius = 8.0
        self.rightButton.layer.cornerRadius = 8.0
    }

    @IBAction private func optionButtonDidPressed(sender: UIButton) {
        var selectedBtn: UIButton!
        var normalBtn: UIButton!
        var selectedImage: UIImage!
        var normalImage: UIImage!
        var selectedValue: String!

        if sender == self.leftButton {
            selectedBtn = self.leftButton
            selectedImage = UIImage(named: self.selectedIcons[0])
            normalBtn = self.rightButton
            normalImage = UIImage(named: self.normalIcons[1])
            selectedValue = self.values[0]
        }
        else {
            selectedBtn = self.rightButton
            selectedImage = UIImage(named: self.selectedIcons[1])
            normalBtn = self.leftButton
            normalImage = UIImage(named: self.normalIcons[0])
            selectedValue = self.values[1]
        }

        selectedBtn.backgroundColor = self.selectedColor
        selectedBtn.setImage(selectedImage, for: .normal)

        normalBtn.backgroundColor = self.normalColor
        normalBtn.setImage(normalImage, for: .normal)

        self.delegate?.onSegmentAction(type: self.type, value: selectedValue)
    }
}
