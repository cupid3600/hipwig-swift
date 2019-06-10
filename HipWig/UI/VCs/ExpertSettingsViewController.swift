//
//  ExpertSettingsViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/11/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD
import MulticastDelegateSwift

fileprivate enum ConnectInstagramState: Int {
    case connected
    case disconnected
}

class ExpertSettingsViewController: BaseViewController {
    
    //MARK: - Outlets -
    @IBOutlet private weak var segmentView: ExpertProgressView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var logoutButton: UIButton!
    
    //MARK: - Properties -
    fileprivate var connectInstagramState: ConnectInstagramState {
        get {
            return .connected
        }
    }
    
    var user: InternalExpert?
    
    private weak var currentViewController: UIViewController?
    private let api = RequestsManager.manager
    private let account = AccountManager.manager
    private let stateCoordinator = DefineExpertViewStateCoordinator()
    
    //MARK: - Life cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let category = SettingsFeatureFlagCategoryImplementation.default
        self.logoutButton.isHidden = !category.logoutEnabled
        
        analytics.log(.open(screen: .settions))
    }
    
    deinit {
        if let target = MainStoryboard.tabBarViewController {
            target.tabBarViewControllerDelegate -= self
        }
        
        print(#file + " " + #function)
    }
    
    //MARK: - Actions -
    @IBAction func logoutDidSelect() {
        self.account.logout { error in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                MainStoryboard.showLogin() 
            }
        }
    }
    
    //MARK: - Private -
    private func onLoad() {
        if let user = account.user {
            self.user = InternalExpert(user: user)
        }
        
        self.setup(segmentView: self.segmentView)
        
        let directions = self.user?.directions ?? []
        let state = directions.count < ExpertSkill.maxSkills ? .directions : self.stateCoordinator.state
        
        self.reload(for: state)
        self.segmentView.selectSegment(self.stateCoordinator.state.rawValue)
        
        self.view.adjustConstraints()

        if let target = MainStoryboard.tabBarViewController {
            target.tabBarViewControllerDelegate += self
        }
    }
     
    private func setup(segmentView: SegmenView) {
        segmentView.delegate = self
        segmentView.titles = [
            "become_an_expert.images.title".localized,
            "become_an_expert.payPal.title".localized,
            "become_an_expert.expertis.title".localized
        ]
    }
    
    private func reload(for state: DefineExpertViewState, forceReload: Bool = false) {
        self.stateCoordinator.update(with: state, forceReload: forceReload) { [weak self] stateToReload in
            guard let `self` = self else { return }
            
            if let state = stateToReload {
                switch state {
                case .images:
                    self.prepareImagesView(with: self.connectInstagramState)
                case .paypalEmail:
                    self.preparePaypalEmailRequestView()
                case .directions:
                    self.prepareExpertiesDirectionsView()
                }
            }
        }
    }
    
    private var shouldShowDirectionsAlert: Bool {
        if let user = self.user {
            return user.directions.count < 3
        } else {
            return false
        }
    }
    
    private func preparePaypalEmailRequestView() {
        let viewController: SelectExpertPayPalEmailViewController = BecomeAnExpertStoryboard.instantiate()
        viewController.user = self.user
        viewController.delegate = self
        
        self.placeViewControllerInContainer(viewController: viewController)
    }
    
    private func prepareExpertiesDirectionsView() {
        let viewController: SelectExpertiesDirectionsViewController = BecomeAnExpertStoryboard.instantiate()
        viewController.user = self.user
        viewController.delegate = self
        viewController.usePublishProfileButton = false
        
        self.placeViewControllerInContainer(viewController: viewController)
    }
    
    private func prepareImagesView(with connectInstagramState: ConnectInstagramState) {
        var targetViewControler: UIViewController? = nil
        
        switch connectInstagramState {
        case .connected:
            let viewController: ConnectedInstargamProfileViewController = BecomeAnExpertStoryboard.instantiate()
            viewController.delegate = self
            viewController.user = self.user
            viewController.allowPlayVideo = false
            targetViewControler = viewController
        case .disconnected:
            let viewController: StartConnectToInstagramViewController = BecomeAnExpertStoryboard.instantiate()
            viewController.delegate = self
            
            targetViewControler = viewController
        }
        
        self.placeViewControllerInContainer(viewController: targetViewControler)
    }
    
    private func placeViewControllerInContainer(viewController: UIViewController?) {
        self.currentViewController?.dissmiss()
        
        self.currentViewController = viewController
        if let viewController = viewController {
            self.place(viewController: viewController, on: containerView)
        }
    }
}

//MARK: - StartConnectToInstagramViewControllerDelegate
extension ExpertSettingsViewController : StartConnectToInstagramViewControllerDelegate {
    
    func didConnectToInstagram() {
        self.reload(for: self.stateCoordinator.state, forceReload: true)
    }
}

//MARK: - ConnectedInstargamProfileViewControllerDelegate
extension ExpertSettingsViewController : ConnectedInstargamProfileViewControllerDelegate {
    
    func didChangeProfilePhoto() {
        guard let image = self.user?.updatingPhoto else {
            return
        }

        self.api.uploadUserPhoto(image: image) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                logger.log(error)
            }
        }
    }
    
    func didSelectDissconnectInstagram() {

    }
    
    func didMakeVideo(url: String) {
        self.uploadUserVideo(url: url)
    }
}

//MARK: - SelectExpertiesDirectionsViewControllerDelegate
extension ExpertSettingsViewController: SelectExpertiesDirectionsViewControllerDelegate {
    
    func didChangeLocation(with location: String?) {
        self.user?.location = location
        self.updateUser(forceReload: false)
    }
    
    func didSelectDirection(with directions: [ExpertSkill]) {
        self.user?.directions = directions
        
        if directions.count == ExpertSkill.maxSkills {
            self.updateUser(forceReload: false)
        }
    }
    
    private func uploadUserVideo(url videoURL: String) {
        guard let url = URL(string: videoURL) else {
            return
        }
        
        self.api.uploadVideo(with: url) { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let user):
                self.user = InternalExpert(user: user)
                self.reload(for: self.stateCoordinator.state, forceReload: true)
            case .failure(let error):
                logger.log(error)
            }
        }
    }
}

//MARK: - SelectExpertPayPalEmailViewControllerDelegate
extension ExpertSettingsViewController: SelectExpertPayPalEmailViewControllerDelegate {
    
    func didChangePayPalEmail(shouldSave: Bool, email: String?, error: String?) {
        var hasEmail = false
        if let email = email, !email.isEmpty {
            hasEmail = true
        }
        
        if shouldSave && error == nil && hasEmail {
            self.user?.payPalEmail = email
            self.updateUser()
        }
    }
    
    private func updateUser(forceReload: Bool = true) {
        if let userID = self.account.myUserID, let user = self.user {
            self.api.updateUser(with: user, for: userID) { [weak self] result in
                guard let `self` = self else { return }
                
                SVProgressHUD.dismiss()
                
                switch result {
                case .success(let user):
                    self.user = InternalExpert(user: user)
                    self.reload(for: self.stateCoordinator.state, forceReload: forceReload)
                case .failure(let error):
                    logger.log(error)
                }
            }
        }
    }
}

//MARK: - SegmentViewDelegate
extension ExpertSettingsViewController : SegmentViewDelegate {
    
    func segmentView(_ segmentView: SegmenView, shouldSelectSegmentWithIndex index: Int) -> Bool {
        var shouldSelect = false
        
        DispatchQueue.global(qos: .userInteractive).sync {
            let state = DefineExpertViewState(rawValue: index) ?? .images
            
            self.stateCoordinator.update(with: state, forceReload: false) { [weak self] stateToReload in
                guard let `self` = self else { return }
                
                if let state = stateToReload {
                    let directinsWasSelected = stateCoordinator.prevState != nil && stateCoordinator.prevState! == .directions
                    
                    switch state {
                    case .images, .paypalEmail:
                        if directinsWasSelected && self.shouldShowDirectionsAlert {
                            shouldSelect = false
                        } else {
                            shouldSelect = true
                        }
                    case .directions:
                        shouldSelect = true
                    }
                } else {
                    shouldSelect = true
                }
                
                if self.stateCoordinator.prevState != nil {
                    self.stateCoordinator.set(state: stateCoordinator.prevState!)
                }
            }
        }
        
        if !shouldSelect {
            ModalStoryboard.showDirectionsWarningAlert()
        }
        
        return shouldSelect
    }
    
    func segmentView(_ segmentView: SegmenView, didSelectSegmentWithIndex index: Int) {
        let newState = DefineExpertViewState(rawValue: index) ?? .images
        
        self.reload(for: newState)
    }
}

//MARK: - UITabBarControllerDelegate
extension ExpertSettingsViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if self.shouldShowDirectionsAlert {
            ModalStoryboard.showDirectionsWarningAlert()
            
            return false
        } else {
            return true
        }
    }
}
