//
//  UserSettingsViewController.swift
//  HipWig
//
//  Created by Alexey on 1/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD
import GoogleSignIn
import MessageUI

class UserSettingsViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var settingsTitleLabel: UILabel!
    @IBOutlet private weak var logoutButton: UIButton!
    @IBOutlet private weak var notificationSwitchView: SwitchView!
    @IBOutlet private weak var notificationsTextLabel: UILabel!
    @IBOutlet private weak var freeMinutesTextLabel: UILabel!
    @IBOutlet private weak var subscriptionDateTextLabel: UILabel!
    @IBOutlet private weak var upgradePlanButton: UIButton!
    @IBOutlet private weak var becomeAnExpertButton: UIButton!
    @IBOutlet private weak var emailServiceButton: UIButton!
    @IBOutlet private weak var tempSeparatorViews: UIView!
    @IBOutlet private var separatorViews: [UIView]!
    @IBOutlet private weak var heightBetweenButtons: NSLayoutConstraint!
    @IBOutlet private weak var notificationActivityIndicator: UIActivityIndicatorView!

    //MARK: - Properties -
    private let account: AccountManager = AccountManager.manager
    private let supportEmail = "support@hipwig.com"
    private let minutesFormatter = NumberFormatter()

    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let category = SettingsFeatureFlagCategoryImplementation.default
        
        self.becomeAnExpertButton.isHidden = !category.becomeExpertEnabled
        self.logoutButton.isHidden = !category.logoutEnabled
        
        let expertDetailsCategory = ExpertDetailsFeatureFlagCategoryImplementation.default
        let freeCalls = expertDetailsCategory.freeCalls
        self.upgradePlanButton.isHidden = freeCalls
        self.subscriptionDateTextLabel.isHidden = freeCalls
        self.tempSeparatorViews.isHidden = freeCalls

        let freeMinutes = expertDetailsCategory.freeMinutes
        self.freeMinutesTextLabel.isHidden = freeMinutes

        let becomeAnAdvisor = expertDetailsCategory.becomeAnAdvisor
        self.becomeAnExpertButton.isHidden = !becomeAnAdvisor

        self.setup(notificationSwitchView: self.notificationSwitchView)
        self.logoutButton.isUserInteractionEnabled = true
        
        self.account.updateUser { [weak self] in
            guard let `self` = self else { return }
            
            if let user = self.account.user {
                let minutes = Double(user.availableTime / 60.0)
                let minutesText = self.minutesFormatter.string(from: NSNumber(value: minutes)) ?? "0"
                
                self.freeMinutesTextLabel.text = "Available minutes: " + minutesText

                if let raw = user.subscribedTo {
                    if let date = DateFormatters.defaultFormatter().date(from: raw) {
                        let formatted = DateFormatters.subscriptionFormatter().string(from: date)
                        
                        self.subscriptionDateTextLabel.text = String(format: "Subscription till: %@", formatted)
                    } else {
                        self.subscriptionDateTextLabel.text = String(format: "Subscription till: -")
                    }
                }
            }
        }
                
        NotificationCenter.addApplicationDidBecomeActiveObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.setup(notificationSwitchView: self.notificationSwitchView)
        }
        
        analytics.log(.open(screen: .settions))
    }
    
    deinit {
        print(#file + " " + #function)
    }

    //MARK: - Actions -
    @IBAction private func logoutButtonDidPressed() {
        self.account.logout { error in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                MainStoryboard.showLogin()
            }
        }
    }
    
    @IBAction private func upgradePlanDidPressed() {
        MainStoryboard.showBuySubscriptionScreen(from: self, backAction: { vc, _ in
            vc.dismiss(animated: true)
        }) { vc in
            vc.dismiss(animated: true)
        }
    }
    
    @IBAction private func becomeAnExpertDidPressed() {
        analytics.log(.open(screen: .becomeExpert))
        
        BecomeAnExpertStoryboard.showStartBecomeAnExpert(from: self)
    }
    
    @IBAction private func emailServiceDidPressed() {
        if MFMailComposeViewController.canSendMail() {
            let composeViewController = MFMailComposeViewController()
            composeViewController.mailComposeDelegate = self
            composeViewController.setSubject("HipWig support email")
            composeViewController.setToRecipients([self.supportEmail])
            
            self.present(composeViewController, animated: true, completion: nil)
        } else {
            ModalStoryboard.showUnavailableSendMessage()
        }
    }

    //MARK: - Private  -
    private func onLoad() {
        self.settingsTitleLabel.text = "settings.title".localized
        self.settingsTitleLabel.textColor = .white
        
        self.notificationsTextLabel.textColor = .white
        self.notificationsTextLabel.font = Font.regular.of(size: 16)
        self.notificationsTextLabel.text = "settings.notifications".localized

        self.freeMinutesTextLabel.textColor = .white
        self.freeMinutesTextLabel.font = Font.regular.of(size: 16)
        self.freeMinutesTextLabel.text = "Available minutes:"

        self.subscriptionDateTextLabel.textColor = .white
        self.subscriptionDateTextLabel.font = Font.regular.of(size: 16)
        self.subscriptionDateTextLabel.text = "Subscription till:"

        self.setup(seprators: self.separatorViews)
        self.setup(upgradePlanButton: self.upgradePlanButton)
        self.setup(becomeAnExpertButton: self.becomeAnExpertButton)
        self.setup(emailService: self.emailServiceButton)
        self.setup(notificationSwitchView: self.notificationSwitchView)
        self.logoutButton.titleLabel?.font = self.logoutButton.titleLabel?.font.adjusted
        
        NotificationCenter.addWillEnterForegroundObserver { [weak self] in
            guard let `self` = self else { return }
            self.setup(notificationSwitchView: self.notificationSwitchView)
        }

        let deviceType = UIDevice.current.deviceType
        switch deviceType {
        case .iPhone5, .iPhone4, .iPhone5S:
            self.heightBetweenButtons.constant = 15.0
        default:
            break
        }
        
        self.view.adjustConstraints()

        self.minutesFormatter.numberStyle = NumberFormatter.Style.decimal
        self.minutesFormatter.usesGroupingSeparator = true
        self.minutesFormatter.groupingSeparator = ","
        self.minutesFormatter.maximumFractionDigits = 1
        self.minutesFormatter.minimumFractionDigits = 0
    }
    
    private func setup(seprators: [UIView]) {
        seprators.forEach {
            $0.backgroundColor = kBackgroundColor
        }
    }
    
    private func setup(becomeAnExpertButton button: UIButton) {
        button.backgroundColor = disabledColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Font.regular.of(size: 16)
        button.setTitle("settings.become_an_expert".localized, for: .normal)
        button.adjustsImageWhenHighlighted = false
    }
    
    private func setup(emailService button: UIButton) {
        button.setTitleColor(selectedColor, for: .normal)
        button.setTitle("settings.email_customer_service".localized, for: .normal)
        button.backgroundColor = disabledColor
        button.titleLabel?.font = Font.regular.of(size: 16)
        button.adjustsImageWhenHighlighted = false 
    }
    
    private func setup(upgradePlanButton button: UIButton) {
        button.setTitleColor(kTextColor, for: .normal)
        button.backgroundColor = selectedColor
        button.titleLabel?.font = Font.regular.of(size: 16)
        button.setTitle("settings.update_plan".localized, for: .normal)
        button.adjustsImageWhenHighlighted = false
    }
    
    private func setup(notificationSwitchView switchView: SwitchView) {
        
        self.notificationActivityIndicator.startAnimating()
        
        AppDelegate.shared.notificationsEnabled { [weak self] value, _ in
            self?.notificationActivityIndicator.stopAnimating()
            
            switchView.set(isOn: value, handleSelection: false)
        }
        
        switchView.changeValueHandler = { [weak self] sender, value in
            self?.notificationActivityIndicator.startAnimating()
            
            AppDelegate.shared.notificationsEnabledIfAvailable(value) { [weak self] value in
                sender.set(isOn: value, animated: true, handleSelection: false)
                
                self?.notificationActivityIndicator.stopAnimating()
            }
        }
    }
}

//MARK: - MFMailComposeViewControllerDelegate
extension UserSettingsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        if let _ = error {
            ModalStoryboard.showSupportMessageWasntSentWarning()
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
}
