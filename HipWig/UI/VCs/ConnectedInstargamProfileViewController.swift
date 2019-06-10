//
//  ConnctedInstargamProfileViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire
import Kingfisher

protocol ConnectedInstargamProfileViewControllerDelegate: class {
    func didSelectDissconnectInstagram()
    func didMakeVideo(url: String)
    func didChangeProfilePhoto()
}

class ConnectedInstargamProfileViewController: UIViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var dissconnectInstagramButton: UIButton!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var connectedAccountContainerView: UIView!
    @IBOutlet private weak var profileIconImageView: AnimatedImageView!
    @IBOutlet private weak var instagramAccountLabel: UILabel!
    @IBOutlet private weak var videosIconImageView: UIImageView!
    @IBOutlet private weak var changeProfileIconButton: UIButton!
    @IBOutlet private weak var recordVideoButton: UIButton!
    @IBOutlet private weak var videoPlayerView: VideoPlayerView!
    @IBOutlet private weak var loadVideoView: UIActivityIndicatorView!
    
    //MARK: - Properties -
    weak var delegate: ConnectedInstargamProfileViewControllerDelegate?
    var user: InternalExpert?
    var allowPlayVideo: Bool = true
    
    private var cameraControllerSource: UIViewController?
    private let minSize = CGSize(width: 400.0.adjusted, height: 400.0.adjusted)
    private lazy var cropParameters = CroppingParameters(isEnabled: false, allowResizing: true, allowMoving: true, minimumSize: minSize)
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.fetchUsersVideoURL()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(connectedAccountContainerView: self.connectedAccountContainerView)
        self.setup(detailsLabel: self.detailsLabel)
        self.setup(instagramAccountLabel: self.instagramAccountLabel)

        if let newImage = self.user?.updatingPhoto {
            self.profileIconImageView.image = newImage
        } else if let userImage = self.user?.userImage {
            self.updateProfileImageView(with: userImage)
        }

        self.videoPlayerView.usePlayButton = allowPlayVideo
        self.updateLoadVideoActivityIndicator(show: true)
        
        NotificationCenter.addApplicationDidBecomeActiveObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.fetchUsersVideoURL()
        }
        
        self.view.adjustConstraints()
        self.detailsLabel.font = self.detailsLabel.font.adjusted
        self.instagramAccountLabel.font = self.instagramAccountLabel.font.adjusted
        self.changeProfileIconButton.titleLabel?.font = self.changeProfileIconButton.titleLabel?.font?.adjusted
        self.recordVideoButton.titleLabel?.font = self.recordVideoButton.titleLabel?.font?.adjusted
    }
    
    private func fetchUsersVideoURL() {
        self.user?.fetchPlayVideoURL { [weak self] url in
            guard let `self` = self else { return }
            
            self.updateLoadVideoActivityIndicator(show: false)
            
            if let url = url {
                self.videoPlayerView.setVideo(url)
            } else {
                self.updateVideoImageView(with: false)
            }
        }
    }
    
    private func updateLoadVideoActivityIndicator(show: Bool) {
        if show {
            self.loadVideoView.startAnimating()
        } else {
            self.loadVideoView.stopAnimating()
        }
    } 
    
    private func setup(detailsLabel label: UILabel) {
        label.textColor = textColor2
        label.font = Font.regular.of(size: 16)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        
        label.attributedText = NSMutableAttributedString(string: "become_an_expert.images.connected_description".localized,
                                                         attributes: [.paragraphStyle: paragraphStyle])
    }
    
    private func setup(instagramAccountLabel label: UILabel) {
        label.textColor = .white
        label.textAlignment = .center
        label.font = Font.regular.of(size: 15)
        label.text = "become_an_expert.images.connected_to_instagram_button_title".localized
    }
    
    private func updateProfileImageView(with urlValue: String) {
        self.profileIconImageView.setImage(urlValue)
    }
    
    private func updateVideoImageView(with hasVideo: Bool) {
        if hasVideo {
            self.videosIconImageView.contentMode = .scaleAspectFill
        } else {
            self.videosIconImageView.image = UIImage(named: "expert_empty_video")
            self.videosIconImageView.contentMode = .center
        }
    }

    private func setup(changeProfileIconButton button: UIButton) {
        let textColor = selectedColor
        
        button.setTitleColor(textColor, for: .normal)
        button.setTitle("become_an_expert.images.change_photo".localized, for: .normal)
    }
    
    private func setup(recordVideoButton button: UIButton) {
        let textColor = selectedColor
        
        button.setTitleColor(textColor, for: .normal)
        button.setTitle("become_an_expert.images.record_video.localized", for: .normal)
    }
    
    private func setup(connectedAccountContainerView view: UIView) {
        view.layer.cornerRadius = 8.adjusted
        view.clipsToBounds = true 
    }

    private func fetchPhotoFromCamera() {
        let cameraViewController = CameraViewController(croppingParameters: self.cropParameters) { [weak self] image, _ in
            guard let `self` = self else { return }
            
            if image != nil {
                self.user?.updatingPhoto = image
                self.profileIconImageView.image = image
            }
            
            self.cameraControllerSource?.dismiss(animated: true) {
                self.delegate?.didChangeProfilePhoto()
            }
        }
        
        self.cameraControllerSource = cameraViewController
        
        self.present(cameraViewController, animated: true)
    }

    private func fetchPhotoFromLibrary() {
        let imagePickerViewController = CameraViewController.imagePickerViewController(croppingParameters: self.cropParameters) { [weak self] image, _ in
            guard let `self` = self else { return }
            
            if image != nil {
                self.user?.updatingPhoto = image
                self.profileIconImageView.image = image
            }
            
            self.dismiss(animated: true) {
                self.delegate?.didChangeProfilePhoto()
            }
        }
        
        self.cameraControllerSource = imagePickerViewController
        
        self.present(imagePickerViewController, animated: true)
    }

    //MARK: - Actions -
    @IBAction func dissconnectInstagramDidSelect(_ sender: UIButton) {
        self.delegate?.didSelectDissconnectInstagram()
    }
    
    @IBAction func changePhotoDidSelect(_ sender: UIButton) {
        ModalStoryboard.showSelectImageView(cameraSourceClosure: { [weak self] in
            guard let `self` = self else { return }
            
            self.fetchPhotoFromCamera()
        }) { [weak self] in
            guard let `self` = self else { return }
            
            self.fetchPhotoFromLibrary()
        } 
    }
    
    @IBAction func makeVideoDidSelect(_ sender: UIButton) {
        DispatchQueue.main.async {
            let viewController: RecordVideoViewController = BecomeAnExpertStoryboard.instantiate()
            viewController.delegate = self
            
            SVProgressHUD.show()
            self.user?.fetchPlayVideoURL(allowLoading: true) { [weak self] url in
                guard let `self` = self else { return }
                
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    viewController.videoURL = url
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
    }
}

//MARK: - RecordVideoViewControllerDelegate
extension ConnectedInstargamProfileViewController: RecordVideoViewControllerDelegate {
    
    func controller(_ controller: RecordVideoViewController, didFinishWithVideoURL videoURL: URL) {
        self.user?.video = videoURL.absoluteString
        self.user?.videoWasRecorded = true
        
        self.delegate?.didMakeVideo(url: videoURL.absoluteString)
    }
}
