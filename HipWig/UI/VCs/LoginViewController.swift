//
//  LoginViewController.swift
//  HipWig
//
//  Created by Alexey on 1/15/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn
import SVProgressHUD
import ActiveLabel
import SafariServices

class LoginViewController: VideoSplashViewController, GIDSignInUIDelegate {

    //MARK: - Outlets -
    @IBOutlet private var facebookLoginButton: FacebookButton!
    @IBOutlet private var googleLoginButton: GoogleButton!
    @IBOutlet private var instagramLoginButton: InstargamButton!
    @IBOutlet private var privacyTextLabel: ActiveLabel!
    @IBOutlet private var detailsLabel: UILabel!
    @IBOutlet private var logoLabel: UILabel!

    //MARK: - Properties -
    private let account = AccountManager.manager
    private let api = RequestsManager.manager
    private let resourcesCategory = LogInStaticResourcesCategoryImplementation.default
    private let videoProvider = VideosProvider.provider
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()

        self.facebookLoginButton.layer.cornerRadius = 12.0
        self.googleLoginButton.layer.cornerRadius = 12.0

        self.videoFrame = view.frame
        self.fillMode = .resizeAspectFill
        self.alwaysRepeat = true
        self.sound = false
        self.alpha = 1.0
        self.backgroundColor = UIColor.black
        self.restartForeground = true
        
        self.view.adjustConstraints()
        
        self.setup(privacyLabel: self.privacyTextLabel)
        self.setup(detailsLabel: self.detailsLabel)
        self.setup(logoLabel: self.logoLabel)
        
        self.updateViewWithFeatureFlags()
        changeAudioSessionToDuckOther()
        
        if self.resourcesCategory.introVideoURLInfo.isDefaultVideo {
            self.contentURL = self.resourcesCategory.defaultIntroVideoURL
        } else {
            let videoURL = self.resourcesCategory.introVideoURLInfo.value
            let localVideoInfo = VideosProvider.provider.hasVideoFile(with: videoURL.absoluteString)
            if localVideoInfo.localVideoExist {
                self.contentURL = localVideoInfo.localVideoURL
            } else {
                self.contentURL = self.resourcesCategory.defaultIntroVideoURL
                
                if reachability.isNetworkReachable {
                    self.loadVideo(with: videoURL.absoluteString)
                }
            }
        }
        
        self.facebookLoginButton.selectedClosure = { [weak self] sender in
            self?.loginWithFacebook()
        }
        
        self.googleLoginButton.selectedClosure = { [weak self] sender in
            self?.loginWithGoogle()
        }
        
        self.instagramLoginButton.selectedClosure = { /*[weak self]*/ sender in
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateInstagramButtonGradient()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        SVProgressHUD.dismiss()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Private -
    private func setup(detailsLabel label: UILabel) {
        label.text = "login.description".localized
        label.font = Font.regular.of(size: 18)
    }
    
    private func setup(logoLabel label: UILabel) {
        label.text = "login.logo".localized
        label.font = UIFont(name: "Satisfy", size: 85)!.adjusted
    }
    
    private func setup(privacyLabel label: ActiveLabel) {
        let termsText = "login.terms_text".localized
        let terms = ActiveType.custom(pattern: "\\b\(termsText)\\b")
        
        let privacyText = "login.policy_text".localized
        let privacy = ActiveType.custom(pattern: "\\b\(privacyText)\\b")
        
        label.enabledTypes = [terms, privacy]
        label.attributedText = NSMutableAttributedString(string: "login.privacy_and_terms_text".localized, attributes: [
            .font: Font.regular.of(size: 14),
            .foregroundColor: UIColor.white.withAlphaComponent(0.78)
        ])
        
        label.numberOfLines = 0
        label.lineSpacing = 0

        label.configureLinkAttribute = { type, attributes, value in
            var attributes = attributes
            
            switch type {
            case .custom:
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                attributes[.foregroundColor] = UIColor.white.withAlphaComponent(0.78)
            default:
                break
            }
            
            return attributes
        }
        
        label.customize { [weak self] label in
            label.handleCustomTap(for: terms) { [weak self] _ in
                self?.showTermsAndConditions()
            }
            
            label.handleCustomTap(for: privacy) { [weak self] _ in
                self?.showPrivacyPolicy()
            }
        }
    }
    
    private func showPrivacyPolicy() {
        if let url = URL(string: "https://www.hipwig.com/privacy-policy") {
            ModalStoryboard.showWEBView(with: url, from: self)
        }
    }
    
    private func showTermsAndConditions() {
        if let url = URL(string: "https://www.hipwig.com/terms-of-use.html") {
            ModalStoryboard.showWEBView(with: url, from: self)
        }
    }
    
    private func updateInstagramButtonGradient() {
        let button = self.instagramLoginButton
        
        let startColor = UIColor(red: 255, green: 144, blue: 87)
        let endColor = UIColor(red: 194, green: 39, blue: 104)
        
        let start = CGPoint(x: 0.0, y: 0.5)
        let finish = CGPoint(x: 1.0, y: 0.5)
        
        button?.applyGradient(with: [startColor, endColor], gradient: .custom(start, finish))
    }
    
    private func loadVideo(with url: String) {
        self.videoProvider.videoFile(videoURL: url) { [weak self] url in
            guard let `self` = self else { return }
            
            if let url = url {
                self.contentURL = url
            }
        }
    }
    
    private func updateViewWithFeatureFlags() {
        let category = SignInFeatureFlagCategoryImplementation.default
        
        self.facebookLoginButton.isHidden = !category.facebookLoginEnabled
        self.googleLoginButton.isHidden = !category.googleLoginEnabled
        self.instagramLoginButton.isHidden = !category.instagramLoginEnabled
    }
    
    private func loginWithFacebook() {
        
        let manager = LoginManager()
        manager.logOut()

        manager.logIn(permissions: ["public_profile", "email"], from: self) { [weak self] result, error in
            guard let `self` = self else { return }
            
            if let error = error {
                logger.log(error)
                return
            }

            guard let isCancelled = result?.isCancelled else {
                return
            }
            
            if isCancelled {
                return
            }

            guard let token = result?.token?.tokenString else {
                return
            }
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
            
            self.api.loginWithFacebook(token: token) { error in
                SVProgressHUD.dismiss()
                
                if let error = error {
                    logger.log(error)
                } else {
                    
                    MainStoryboard.showMainScreen()
                    SocketWrapper.wrapper.connect()

                    analytics.log(.login(type: .facebook))
                }
            }
        }
    }

    private func loginWithGoogle() {
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.uiDelegate = self
        GIDSignIn.sharedInstance()?.signIn()
    }
}

// MARK: - GIDSignInDelegate
extension LoginViewController: GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let err = error {
            let casted = err as NSError
            if casted.code == GIDSignInErrorCode.canceled.rawValue {
                //SKIP
            } else {
                logger.log(casted)
            }
            return
        }
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        
        self.api.loginWithGoogle(token: user.authentication.accessToken) { error in
            SVProgressHUD.dismiss()
            
            if let error = error {
                logger.log(error)
            } else {
                MainStoryboard.showMainScreen()
                SocketWrapper.wrapper.connect()

                analytics.log(.login(type: .google))
            }
        }
    }
}
