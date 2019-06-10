//
//  StartConnectToInstagramViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol StartConnectToInstagramViewControllerDelegate: class {
    func didConnectToInstagram()
}

class StartConnectToInstagramViewController: UIViewController {

    weak var delegate: StartConnectToInstagramViewControllerDelegate?
    
    @IBOutlet private weak var connectToInstagramButton: UIButton!
    @IBOutlet private weak var detailsLabel: UILabel!
    
    private let instagramApi = Instagram.shared
    private let api = RequestsManager.manager

    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.updateInstagramButtonGradient()
    }
    
    private func onLoad() {
        self.setup(detailsLabel: self.detailsLabel)
        self.setup(connectToInstagramButton: self.connectToInstagramButton)
    }
    
    @IBAction func connectToInstagramDidSelect(_ sender: UIButton) {
        if let nvc = self.navigationController {
            self.instagramApi.login(from: nvc, withScopes: [.publicContent], success: { [weak self] in
                guard let `self` = self else { return }
                
                if let accessToken = self.instagramApi.retrieveAccessToken() {
                    self.login(with: accessToken)
                }
            }) { error in
                logger.log(error)
            }
        } 
    }
    
    private func login(with accessToken: String) {
        SVProgressHUD.show()
        
//        self.api.connectInstagram(token: accessToken) { [weak self] error in
//            guard let `self` = self else { return }
//            
//            SVProgressHUD.dismiss()
//            if let error = error {
//                if case RequestsManagerError.userAlreadyExist = error {
//                    SVProgressHUD.showInfo(withStatus: "User with this instagram account already exists")
//                } else {
//                    SVProgressHUD.showError(withStatus: error.localizedDescription)
//                }
//            } else {
//                self.delegate?.didConnectToInstagram()
//            }
//        }
    }
    
    private func setup(connectToInstagramButton button: UIButton) {
        button.setTitle("become_an_expert.images.connect_to_instagram_button_title".localized, for: .normal)
        button.titleLabel?.font = Font.regular.of(size: 16)
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
    }
    
    private func updateInstagramButtonGradient() {
        let button = self.connectToInstagramButton
        
        let startColor = UIColor(red: 255, green: 144, blue: 87)
        let endColor = UIColor(red: 194, green: 39, blue: 104)
        
        let start = CGPoint(x: 0.0, y: 0.5)
        let finish = CGPoint(x: 1.0, y: 0.5)
        
        button?.applyGradient(with: [startColor, endColor], gradient: .custom(start, finish))
    }
    
    private func setup(detailsLabel label: UILabel) {
        label.textColor = UIColor(red: 198, green: 198, blue: 198)
        label.font = Font.light.of(size: 16)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        
        label.attributedText = NSMutableAttributedString(string: "become_an_expert.images.disconnected_description".localized,
                                                         attributes: [.paragraphStyle: paragraphStyle])
    }
}
