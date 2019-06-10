//
//  StartBecomeAnExpertViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 28.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class StartBecomeAnExpertViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var detailsTextLabelLabel: UILabel!
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var separatorLineView: UIView!
    
    private let account: AccountManager = AccountManager.manager
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Actions -
    @IBAction func startDidSelect(_ sender: UIButton) {
        var userDTO: InternalExpert
        if let user = account.user {
            userDTO = InternalExpert(user: user)
        } else {
            userDTO = InternalExpert()
        }
    
        BecomeAnExpertStoryboard.showBecomeAnExpertFlow(from: self, with: userDTO)
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setupSeparatorLineView()
        self.setup(sendRequestButton: self.startButton)
        self.setup(detailsTextLabelLabel: self.detailsTextLabelLabel)
        self.view.adjustConstraints()
    }
    
    private func setup(sendRequestButton button: UIButton) {
        button.titleLabel?.font = Font.regular.of(size: 16)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.titleLabel?.textAlignment = .center
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: -14.0, bottom: 0.0, right: 0.0)
        button.tintColor = .white
        
        button.setTitleColor(kTextColor, for: .normal)
        button.backgroundColor = selectedColor
    }
    
    private func setup(detailsTextLabelLabel label: UILabel) {
        label.textColor = UIColor(red: 198, green: 198, blue: 198)
        label.font = Font.light.of(size: 16)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        
        label.attributedText = NSMutableAttributedString(string: "become_an_expert.start_become_expert.description".localized,
                                                     attributes: [.paragraphStyle: paragraphStyle])
    }
    
    private func setup(resultTextLabel label: UILabel) {
        label.textColor = .white
        label.font = Font.regular.of(size: 16)
        label.numberOfLines = 0
    }
    
    private func setupSeparatorLineView() {
        self.separatorLineView.backgroundColor = kBackgroundColor
    }
}
