//
//  ExpertProfileViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/11/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD

class ExpertProfileViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var clientsCountTitleLabel: UILabel!
    @IBOutlet private weak var clientsCountLabel: UILabel!
    @IBOutlet private weak var erningThisMonthTitleLabel: UILabel!
    @IBOutlet private weak var erningThisMonthLabel: UILabel!
    @IBOutlet private weak var erningTotalTitleLabel: UILabel!
    @IBOutlet private weak var availableForCallsSwitchView: SwitchView!
    @IBOutlet private weak var notificationsSwitchView: SwitchView!
    @IBOutlet private weak var publicSwitchView: SwitchView!
    @IBOutlet private weak var erningTotalLabel: UILabel!
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private var separatorViews: [UIView]!
    @IBOutlet private weak var notificationActivityIndicator: UIActivityIndicatorView!
    
    //MARK: - Properties -
    private let account = AccountManager.manager
    private let api = RequestsManager.manager
    private let currencyFormatter = NumberFormatter()

    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setup(availableForCallsSwitchView: self.availableForCallsSwitchView)
        self.setup(notificationSwitchView: self.notificationsSwitchView)
        self.setup(publicSwitchView: self.publicSwitchView)

        self.api.getExpertStatistics { [weak self] monthEarning, totalEarning, error in
            guard let `self` = self else { return }
            
            let month = self.currencyFormatter.string(from: NSNumber(value: monthEarning))
            self.erningThisMonthLabel.text = month

            let total = self.currencyFormatter.string(from: NSNumber(value: totalEarning))
            self.erningTotalLabel.text = total
        }

        self.account.updateUser { [weak self] in
            guard let `self` = self else { return }
            
            let expert = self.account.user?.expert
            
            self.clientsCountLabel.text = String(format: "%d", expert?.clients ?? 0)
            self.updateView(with: expert)
        }
        
        analytics.log(.open(screen: .profile))
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(seprators: self.separatorViews)

        self.currencyFormatter.numberStyle = .currency
        self.currencyFormatter.currencyCode = "USD"
        self.currencyFormatter.currencyDecimalSeparator = ","
        self.currencyFormatter.minimumFractionDigits = 0
        self.currencyFormatter.maximumFractionDigits = 2

        self.clientsCountLabel.text?.removeAll()
        self.erningTotalLabel.text?.removeAll()
        self.erningThisMonthLabel.text?.removeAll()
        
        self.view.adjustConstraints()
        self.clientsCountTitleLabel.font = self.clientsCountTitleLabel.font.adjusted
        self.clientsCountLabel.font = self.clientsCountLabel.font.adjusted
        self.erningThisMonthTitleLabel.font = self.erningThisMonthTitleLabel.font.adjusted
        self.erningThisMonthLabel.font = self.erningThisMonthLabel.font.adjusted
        self.erningTotalTitleLabel.font = self.erningTotalTitleLabel.font.adjusted
        
        self.contentStackView.spacing = self.contentStackView.spacing.adjusted
        
        NotificationCenter.addApplicationDidBecomeActiveObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.setup(notificationSwitchView: self.notificationsSwitchView)
        }
        
        NotificationCenter.addNotificationStatusChangeObserver { [weak self] value in
            guard let `self` = self else { return }
            
            self.notificationsSwitchView.set(isOn: value, handleSelection: false)
        }
    }
//    
//    @IBAction private func coinListSelected(_ button: UIButton) {
//        ModalStoryboard.showCoinList()
//    }
    
    private func updateView(with expert: Expert?) {
        self.availableForCallsSwitchView.set(isOn: expert?.available ?? false, handleSelection: false)
        
        self.notificationActivityIndicator.startAnimating()
        AppDelegate.shared.notificationsEnabled(false) { value, some in
            self.notificationActivityIndicator.stopAnimating()
            self.notificationsSwitchView.set(isOn: value, handleSelection: false)
        }
        
        self.publicSwitchView.set(isOn: expert?.publicProfile ?? false, handleSelection: false)
    }
    
    private func setup(availableForCallsSwitchView switchView: SwitchView) {
        switchView.changeValueHandler = { [weak self] _, value in
            guard let `self` = self else { return }

            if let user = self.account.user {
                let userWrapper = InternalExpert(user: user)
                userWrapper.available = value

                self.api.updateUser(with: userWrapper, for: user.id) { result in
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        logger.log(error)
                    }
                }
            }
        }
    }
    
    private func setup(notificationSwitchView switchView: SwitchView) {
        switchView.changeValueHandler = { [weak self] sender, value in
            self?.notificationActivityIndicator.startAnimating()
            
            AppDelegate.shared.notificationsEnabledIfAvailable(value, postEvent: false) { [weak self] value in
                sender.set(isOn: value, animated: true, handleSelection: false)
                
                self?.notificationActivityIndicator.stopAnimating()
            }
        }
    }

    private func setup(publicSwitchView switchView: SwitchView) {
        switchView.changeValueHandler = { [weak self] _, value in
            guard let `self` = self else { return }

            if let user = self.account.user {
                let userWrapper = InternalExpert(user: user)
                userWrapper.publicProfile = value

                self.api.updateUser(with: userWrapper, for: user.id) { result in
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        logger.log(error)
                    }
                }
            }
        }
    }
    
    private func setup(seprators: [UIView]) {
        seprators.forEach {
            $0.backgroundColor = kBackgroundColor
        }
    }
}
