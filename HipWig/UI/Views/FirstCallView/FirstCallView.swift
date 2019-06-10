//
//  FirstCallView.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/8/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class FirstCallView: UIView {
    
    //MARK: - Outlets -
    @IBOutlet private var fistCallTextLabel: UILabel!
    @IBOutlet private var yeaTextLabel: UILabel!
    @IBOutlet private var containerView: UIView!
    
    //MARK: - Life Cycle -
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    //MARK: - Public innterface -
    public class func show(source: UIView) -> FirstCallView? {
        if let view = FirstCallView.fromXib() {
            source.place(view)
            return view
        } else {
            return nil
        }
    }
    
    public func close() {
        self.closeView()
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(fistCallTextLabel: self.fistCallTextLabel)
        self.setup(yeaTextLabel: self.yeaTextLabel)
        self.setup(containerView: self.containerView)
        
        self.yeaTextLabel.font = self.yeaTextLabel.font.adjusted
        self.fistCallTextLabel.font = self.fistCallTextLabel.font.adjusted
        self.adjustConstraints()
    }
    
    private func closeView() {
        UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    private func setup(containerView view: UIView) {
        view.layer.cornerRadius = 8.0.adjusted
        view.layer.borderColor = UIColor(red: 255, green: 79, blue: 154).cgColor
        view.layer.borderWidth = 1.0
    }
    
    private func setup(fistCallTextLabel label: UILabel) {
        label.textColor = UIColor(red: 255, green: 79, blue: 154)
        label.font = Font.regular.of(size: 24)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .center
        label.attributedText = NSMutableAttributedString(string: "first_call.description".localized,
                                                         attributes: [.paragraphStyle: paragraphStyle])
    }
    
    private func setup(yeaTextLabel label: UILabel) {
        label.text = "first_call.yea".localized
        label.font = Font.regular.of(size: 24)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    //MARK: - Actions -
    @IBAction private func closeDidSelected(sender: UIButton) {
        self.closeView()
    } 
}
