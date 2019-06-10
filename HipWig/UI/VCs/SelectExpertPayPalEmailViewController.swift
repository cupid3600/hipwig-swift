//
//  SelectExpertPayPalEmailViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 28.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol SelectExpertPayPalEmailViewControllerDelegate: class {
    func didChangePayPalEmail(shouldSave: Bool, email: String?, error: String?)
}

private struct EmailValidator {
    
    var email: String = ""
    
    var error: String? {
        get {
            if !self.email.isEmpty {
                if self.email.isValidAsEmail {
                    return nil
                } else {
                    return "Email is not valid"
                }
            } else {
                return nil
            }
        }
    }
    
    static var `default`: EmailValidator {
        return EmailValidator(email: "")
    }
}

class SelectExpertPayPalEmailViewController: UIViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var detailsTextLabelLabel: UILabel!
    @IBOutlet private weak var payPalInfoLabelLabel: UILabel!
    @IBOutlet private weak var emailTextField: EmailTextField!
    
    //MARK: - Interface -
    var user: InternalExpert?
    weak var delegate: SelectExpertPayPalEmailViewControllerDelegate?
    
    //MARK: - Properties -
    private var validator: EmailValidator = .default
    private let typeTimer = TypeTimer()
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.emailTextField.text = self.user?.payPalEmail
        self.updatePayPalEmail(with: self.user?.payPalEmail)
        self.updateView(with: self.user?.payPalEmail ?? "")
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(emailTextField: self.emailTextField) 
        self.setup(detailsTextLabelLabel: self.detailsTextLabelLabel)
        self.setup(paypalInfoLabel: self.payPalInfoLabelLabel)
        
        NotificationCenter.addHideKeyboardObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.delegate?.didChangePayPalEmail(shouldSave: true, email: self.validator.email, error: self.validator.error)
        }
        
        self.view.adjustConstraints()
        self.detailsTextLabelLabel.font = self.detailsTextLabelLabel.font.adjusted
        self.payPalInfoLabelLabel.font = self.payPalInfoLabelLabel.font.adjusted
        self.emailTextField.font = self.emailTextField.font?.adjusted
    } 
    
    private func setup(emailTextField textField: EmailTextField) {
        textField.backgroundColor = UIColor(red: 69, green: 79, blue: 99)
        textField.textColor = .white
        textField.textAlignment = .center
        textField.font = Font.medium.of(size: 15)
        
        textField.layer.borderColor = selectedColor.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 12
        textField.addShadow(opacity: 0.2)
        
        let image = UIImage(named: "text_field_clean")!
        textField.clearButtonWithImage(image)
        textField.cleanSelectedClosure = { [weak self] in
            self?.cleanEmailSelected()
        }
        
        textField.attributedPlaceholder = NSAttributedString(string: "become_an_expert.payPal.email_placeholder".localized,
                                                         attributes: [.foregroundColor: UIColor.white])
    }
    
    @objc private func cleanEmailSelected() {
        self.updatePayPalEmail(with: nil)
        self.updateView(with: "")
    }
    
    private func setup(detailsTextLabelLabel label: UILabel) {
        label.textColor = .white
        label.font = Font.light.of(size: 16)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping 
        
        label.text = "become_an_expert.payPal.requirements_description".localized
    }
    
    private func setup(paypalInfoLabel label: UILabel) {
        label.textColor = textColor2
        label.font = Font.light.of(size: 16)
        label.numberOfLines = 0
        label.text = "become_an_expert.payPal.paypal_description".localized
    }
    
    private func updateEmailTextFieldBorder(for text: String) {
        self.emailTextField.layer.borderWidth = text.isEmpty ? 1 : 0
        if text.isValidAsEmail {
            self.emailTextField.backgroundColor = disabledColor
        } else {
            self.emailTextField.backgroundColor = UIColor(red: 69, green: 79, blue: 99)
        }
    }
    
    private func updateView(with enteredText: String) {
        self.updateEmailTextFieldBorder(for: enteredText)
    }
    
    private func updatePayPalEmail(with email: String?, shouldSave: Bool = false) {
        self.validator.email = email?.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) ?? ""
        self.delegate?.didChangePayPalEmail(shouldSave: shouldSave, email: self.validator.email, error: nil)
        
        if email != nil && email!.isValidAsEmail {
            self.emailTextField.rightViewMode = .always
        } else {
            self.emailTextField.rightViewMode = .never
        }
    }
}

extension SelectExpertPayPalEmailViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let enteredText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
        
        self.updatePayPalEmail(with: enteredText)
        self.updateView(with: enteredText)
        
        textField.show(error: nil)
        self.typeTimer.start { [weak self] in
            guard let `self` = self else { return }
            
            self.validator.email = enteredText
            textField.show(error: self.validator.error)
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let enteredText = textField.text ?? ""
        self.updateView(with: enteredText)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let enteredText = textField.text ?? ""
        self.updateView(with: enteredText)
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text?.removeAll()
        self.updatePayPalEmail(with: nil)
        textField.show(error: nil)
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
