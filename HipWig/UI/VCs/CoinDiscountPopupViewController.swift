//
//  CoinDiscountPopupViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/24/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class CoinDiscountPopupViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var discountLabel: UILabel!
    @IBOutlet private weak var coinsLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var saveLabel: UILabel!
    @IBOutlet private weak var saveDiscountLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var addCallCreditsButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var timeContainerView: UIView!
    @IBOutlet private weak var coinDescriptionContainerView: UIView!
    @IBOutlet private weak var priceContainerView: UIView!
    
    //MARK: - Properties -
    private let productService: ProductService = ProductServiceImplementation.default
    private var timer: CountDownTimer?
    
    //MARK: - Interface -
    var completion: ((Bool) -> Void)?
    var titleText: String!
    var leftTime: TimeInterval = 0
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = .clear
        self.showAnimate(with: self.containerView)
        
        self.titleLabel.text = self.titleText
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Actions -
    @IBAction func getDiscountSelected(_ sender: UIButton) {
        
    }
    
    override func backDidSelect(_ sender: UIButton) {
        self.close()
    } 
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(titleLabel: self.titleLabel)
        self.setup(descriptionLabel: self.descriptionLabel)
        self.setup(addCallCreditsButton: self.addCallCreditsButton)
        self.setup(mainContainerView: self.mainContainerView)
        self.setup(timeContainerView: self.timeContainerView)
        self.setup(coinDescriptionContainerView: self.coinDescriptionContainerView)
        self.setup(priceContainerView: self.priceContainerView)
        self.setup(priceLabel: self.priceLabel)
        self.setup(coinsLabel: self.coinsLabel)
        self.setup(discountLabel: self.discountLabel)
        self.setup(timeLabel: self.timeLabel)
        self.setup(saveLabel: self.saveLabel)
        self.setup(saveDiscountLabel: self.saveDiscountLabel)
        
        self.timer = CountDownTimer(interval: self.leftTime)
        self.timer?.intervalChangeClosure = { [weak self] interval in
            guard let `self` = self else { return }
            
            self.productService.leftDiscountTime = interval
            self.timeLabel.text = interval.timeValue
        }
        
        self.timer?.timeOutClosure = { [weak self] in
            guard let `self` = self else { return }
            
            self.productService.leftDiscountTime = 0.0
            self.close()
        }
        
        self.timer?.start()
        
        self.view.adjustConstraints()
    }
    
    private func close() {
        if let completion = self.completion {
            self.removeAnimate(with: self.containerView) {
                completion(false)
            }
        }
    }
    
    private func setup(mainContainerView view: UIView) {
        view.layer.cornerRadius = 8.0.adjusted
        view.layer.borderWidth = 1.adjusted
        view.layer.borderColor = UIColor(red: 255, green: 79, blue: 154).cgColor
    }
    
    private func setup(timeContainerView view: UIView) {
        view.layer.cornerRadius = 8.0.adjusted
        view.layer.borderWidth = 1.adjusted
        view.clipsToBounds = true
        view.layer.borderColor = UIColor(red: 255, green: 79, blue: 154).cgColor
    }
    
    private func setup(coinDescriptionContainerView view: UIView) {
        view.layer.cornerRadius = 8.adjusted
        view.backgroundColor = UIColor(red: 47, green: 34, blue: 54)
    }
    
    private func setup(priceContainerView view: UIView) {
        view.layer.cornerRadius = 8.adjusted
    }
    
    private func setup(saveLabel label: UILabel) {
        label.font = Font.regular.of(size: 20)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(saveDiscountLabel label: UILabel) {
        label.font = Font.bold.of(size: 34)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(coinsLabel label: UILabel) {
        label.font = Font.regular.of(size: 20)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(discountLabel label: UILabel) {
        label.font = Font.regular.of(size: 20)
        label.textAlignment = .center
        label.textColor = UIColor(red: 255, green: 226, blue: 122)
    }
    
    private func setup(titleLabel label: UILabel) {
        label.font = Font.regular.of(size: 24)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(priceLabel label: UILabel) {
        label.font = Font.regular.of(size: 20)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(timeLabel label: UILabel) {
        label.font = Font.regular.of(size: 20)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(descriptionLabel label: UILabel) {
        label.font = Font.light.of(size: 16)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(addCallCreditsButton button: UIButton) {
        button.titleLabel?.font = Font.bold.of(size: 16)
        button.tintColor = textColor2
        button.adjustsImageWhenHighlighted = false
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 255, green: 79, blue: 154)
        button.layer.cornerRadius = 8.0.adjusted
        button.clipsToBounds = true
    }
}
