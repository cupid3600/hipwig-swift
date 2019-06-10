//
//  DefineAnExpertContainerViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD

fileprivate enum ConnectInstagramState: Int {
    case connected
    case disconnected
}

class DefineAnExpertContainerViewController: BaseViewController {

    @IBOutlet private weak var segmentView: ExpertProgressView!
    @IBOutlet private weak var containerView: UIView!
    
    public var user: InternalExpert!
    
    private weak var currentViewController: UIViewController?
    private let api = RequestsManager.manager
    private let accountManager = AccountManager.manager
    fileprivate var connectInstagramState: ConnectInstagramState = .connected
    private let stateCoordinator = DefineExpertViewStateCoordinator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    private func onLoad() {
        self.setup(segmentView: self.segmentView)
        self.reload(for: self.stateCoordinator.state)
        self.segmentView.selectSegment(self.stateCoordinator.state.rawValue)
        
        self.view.adjustConstraints()
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
        self.stateCoordinator.update(with: state, forceReload: forceReload) { [weak self] state in
            guard let `self` = self else { return }
            
            if let state = state {
                switch state {
                case .images:
                    self.prepareImagesView(with: self.connectInstagramState)
                case .paypalEmail:
                    self.preparePaypalEmailRequestView()
                case .directions:
                    self.prepareExpertiesDirectionsView()
                }
            }
            
            self.updateSegmentControl()
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
        
        self.placeViewControllerInContainer(viewController: viewController)
    }
    
    private func prepareImagesView(with connectInstagramState: ConnectInstagramState) {
        var targetViewControler: UIViewController? = nil
        
        switch connectInstagramState {
        case .connected:
            let viewController: ConnectedInstargamProfileViewController = BecomeAnExpertStoryboard.instantiate()
            viewController.delegate = self
            viewController.user = self.user
            
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
extension DefineAnExpertContainerViewController : StartConnectToInstagramViewControllerDelegate {
    
    func didConnectToInstagram() {
        self.reload(for: self.stateCoordinator.state, forceReload: true)
    }
}

//MARK: - ConnectedInstargamProfileViewControllerDelegate
extension DefineAnExpertContainerViewController : ConnectedInstargamProfileViewControllerDelegate {
    
    func didSelectDissconnectInstagram() { 
        self.user.reset()
        self.reload(for: self.stateCoordinator.state, forceReload: true)
    }
    
    func didChangeProfilePhoto() {
        self.reload(for: self.stateCoordinator.state, forceReload: true)
        self.uploadUserImage {
            AppDelegate.shared.sendLocalPushNotificationOnce(content: LocalNotificationContent.ProfilePhotoUploaded.notificationContent)
        }
    }
    
    func didMakeVideo(url: String) {
        analytics.log(.recordVideo)
        
        self.user.video = url
        self.reload(for: self.stateCoordinator.state, forceReload: true)
    } 
}

//MARK: - SelectExpertiesDirectionsViewControllerDelegate
extension DefineAnExpertContainerViewController: SelectExpertiesDirectionsViewControllerDelegate {
    
    func didSelectDirection(with directions: [ExpertSkill]) {
        self.reload(for: self.stateCoordinator.state)
    }
    
    func didSelectPublishProfile() {
        if let userID = self.accountManager.myUserID {
            SVProgressHUD.show()

            self.api.updateUser(with: self.user, for: userID) { [weak self] result in
                guard let `self` = self else { return }
                
                SVProgressHUD.dismiss()
                
                switch result {
                case .success:
                    self.uploadUserVideo {
                        self.navigationController?.popToRootViewController(animated: true)
                        MainStoryboard.showMainScreen()
                        
                        analytics.log(.publishProfile)
                        self.api.publishExpertProfile { _ in }
                    }
                case .failure(let error):
                    logger.log(error)
                }
            }
        }
    }
    
    private func uploadUserVideo(_ completion: @escaping () -> Void) {
        guard let videoURL = self.user.video, let url = URL(string: videoURL) else {
            return
        }
        
        if url.isValidURL && UIApplication.shared.canOpenURL(url) {
            completion()
        } else {
        
            SVProgressHUD.show()
            
            self.api.uploadVideo(with: url) { result in
                SVProgressHUD.dismiss()
                
                switch result {
                case .success:
                    break
                case .failure(let error):
                    SVProgressHUD.showError(withStatus: "Can't upload video, try later.")
                    logger.log(error)
                }
                
                completion()
            }
        }
    }

    private func uploadUserImage(_ completion: @escaping () -> Void) {
        guard let image = self.user.updatingPhoto else {
            return
        }

        self.api.uploadUserPhoto(image: image) { result in
            switch result {
            case .success:
                completion()
            case .failure(let error):
                logger.log(error)
            }
        }
    }
}

//MARK: - SelectExpertPayPalEmailViewControllerDelegate
extension DefineAnExpertContainerViewController: SelectExpertPayPalEmailViewControllerDelegate {
    
    func didChangePayPalEmail(shouldSave: Bool, email: String?, error: String?) {
        if shouldSave && error == nil && email != nil && !email!.isEmpty {
            self.user?.payPalEmail = email
        }
        
        self.reload(for: self.stateCoordinator.state)
    }
}

//MARK: - SegmentViewDelegate
extension DefineAnExpertContainerViewController : SegmentViewDelegate {
    
    func segmentView(_ segmentView: SegmenView, shouldSelectSegmentWithIndex index: Int) -> Bool {
        return true
    }
    
    func segmentView(_ segmentView: SegmenView, didSelectSegmentWithIndex index: Int) {
        let state = DefineExpertViewState(rawValue: index) ?? .images
        
        self.reload(for: state)
    }
    
    private func updateSegmentControl() {
        DefineExpertViewState.allCases.forEach { state in
            switch state {
            case .images: 
                self.segmentView.setSegmentAsMarked(with: state.rawValue, condition: self.user.imagesReadyToSave)
            case .directions:
                self.segmentView.setSegmentAsMarked(with: state.rawValue, condition: self.user.directionsReadyToSave)
            case .paypalEmail:
                self.segmentView.setSegmentAsMarked(with: state.rawValue, condition: self.user.emailReadyToSave)
            }
        }
    }
}
