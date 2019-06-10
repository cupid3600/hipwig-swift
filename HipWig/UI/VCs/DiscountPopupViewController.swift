
//
//  DiscountPopupViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/7/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class DiscountPopupViewController: BaseViewController {
    
    //MARK: - Outlets -
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var circleView: UIView!
    @IBOutlet private weak var purchaseButton: UIButton!
    @IBOutlet private weak var leftUseOfferLabel: UILabel!
    @IBOutlet private weak var discountPercentsLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var popupHeaderLabel: UILabel!

    public var purchaseCompletion: (() -> (Void))?
    public var cancelAction: (() -> (Void))?

    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.backgroundColor = .clear
        self.showAnimate(with: self.containerView)
        self.setup(circleView: self.circleView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.circleView.layer.cornerRadius = self.circleView.bounds.width / 2.0
    }
    
    override func backDidSelect(_ sender: UIButton) {
        self.removeAnimate(with: self.containerView) {
            self.cancelAction?()
        }
    }

    @IBAction func purchaseDidSelect(_ sender: UIButton) {
        self.removeAnimate(with: self.containerView) {
            self.purchaseCompletion?()
        }
    }

    //MARK: - Private -
    private func onLoad() {
        self.setup(containerView: self.containerView)
        self.setup(purchaseButton: self.purchaseButton)
        self.setup(detailsLabel: self.detailsLabel)
        self.setup(leftUseOfferLabel: self.leftUseOfferLabel)
        self.setup(discountPercentsLabel: self.discountPercentsLabel)
        self.setup(popupHeaderLabel: self.popupHeaderLabel)
        
        self.view.adjustConstraints()
    }
    
    private func setup(containerView view: UIView) {
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 255, green: 79, blue: 154).cgColor
    }
    
    private func setup(circleView view: UIView) {
        view.layer.cornerRadius = view.bounds.width / 2.0
    }
    
    private func setup(purchaseButton button: UIButton) {
        button.titleLabel?.font = Font.regular.of(size: 16)
        button.layer.cornerRadius = 8.adjusted
        button.clipsToBounds = true
        button.titleLabel?.textAlignment = .center
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: -14.0, bottom: 0.0, right: 0.0)
        button.tintColor = .white
        
        button.setTitleColor(kTextColor, for: .normal)
        button.setTitle("discount.purchase_monthly_plan".localized, for: .normal)
        button.backgroundColor = selectedColor
    }
    
    private func setup(discountPercentsLabel label: UILabel) {
        label.textColor = UIColor(red: 255, green: 79, blue: 154)
        label.font = Font.regular.of(size: 36)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .center
        label.attributedText = NSMutableAttributedString(string: "discount.discount_price_text".localized, attributes: [.paragraphStyle: paragraphStyle])
    }
    
    private func setup(leftUseOfferLabel label: UILabel) {
        label.text = "discount.let_us_offer_you_text".localized
        label.font = Font.light.of(size: 16)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(popupHeaderLabel label: UILabel) {
        label.text = "discount.please_dont_go_text".localized
        label.font = Font.regular.of(size: 24)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(detailsLabel label: UILabel) {
        label.text = "discount.for_first_month_text".localized
        label.font = Font.light.of(size: 16)
        label.textAlignment = .center
        label.textColor = .white
    }
}
