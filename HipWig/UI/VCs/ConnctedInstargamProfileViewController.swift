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
import AlamofireImage

protocol ConnectedInstargamProfileViewControllerDelegate: class {
    func didSelectDissconnectInstagram()
    func didSelectChangePhoto()
    func didSelectMakeVideo()
}

class ConnectedInstargamProfileViewController: UIViewController {

    @IBOutlet private weak var dissconnectInstagramButton: UIButton!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var connectedAccountContainerView: UIView!
    @IBOutlet private weak var profileIconImageView: UIImageView!
    @IBOutlet private weak var instagramAccountLabel: UILabel!
    @IBOutlet private weak var videosIconImageView: UIImageView!
    @IBOutlet private weak var changeProfileIconButton: UIButton!
    @IBOutlet private weak var recordVideoButton: UIButton!
    
    weak var delegate: ConnectedInstargamProfileViewControllerDelegate?
    var user: InternalExpert!
    private var api = Instagram.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    } 
    
    private func onLoad() {
        self.setup(changeProfileIconButton: self.changeProfileIconButton)
        self.setup(recordVideoButton: self.recordVideoButton)
        self.setup(connectedAccountContainerView: self.connectedAccountContainerView)
        self.setup(detailsLabel: self.detailsLabel)
        self.setup(instagramAccountLabel: self.instagramAccountLabel)
        
        self.loadUserInstagramProfile()
        //FIXME: remove after
        self.updateVideoImageView(with: false)
    }
    
    private func loadUserInstagramProfile() {
        if api.isAuthenticated {
            api.user("self", success: { user in
                print(user)
                self.user.userImage = user.profilePicture
                self.updateProfileImageView(with: user.profilePicture)
            }) { error in
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        } else {
            //TODO: do something else
        }
    }
    
    private func setup(detailsLabel label: UILabel) {
        label.textColor = UIColor(displayP3Red: 167/255.0, green: 173/255.0, blue: 186/255.0, alpha: 1.0)
        label.font = UIFont(name: "OpenSans", size: 16.0)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        
        label.attributedText = NSMutableAttributedString(string: """
That’s fun,
Record a profile video and tell more about yourself.

""", attributes: [.paragraphStyle: paragraphStyle])
    }
    
    private func setup(instagramAccountLabel label: UILabel) {
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont(name: "OpenSans", size: 15.0)
        label.text = "Instagram account connected"
    }
    
    private func updateProfileImageView(with url: URL) {
        Alamofire.request(url).responseImage { response in
            if let image = response.result.value {
                self.profileIconImageView.image = image
            }
        }
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
        let textColor = UIColor(displayP3Red: 106/255.0, green: 239/255.0, blue: 207/255.0, alpha: 1.0)
        
        button.setTitleColor(textColor, for: .normal)
        button.setTitle("change photo", for: .normal)
    }
    
    private func setup(recordVideoButton button: UIButton) {
        let textColor = UIColor(displayP3Red: 106/255.0, green: 239/255.0, blue: 207/255.0, alpha: 1.0)
        
        button.setTitleColor(textColor, for: .normal)
        button.setTitle("record video", for: .normal)
    }
    
    private func setup(connectedAccountContainerView view: UIView) {
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.backgroundColor = UIColor(displayP3Red: 70.0/255.0, green: 75.0/255.0, blue: 97.0/255.0, alpha: 1.0)
    }
    
    @IBAction func dissconnectInstagramDidSelect(_ sender: UIButton) {
        if api.isAuthenticated {
            api.logout()
        }
        
        self.delegate?.didSelectDissconnectInstagram()
    }
    
    @IBAction func changePhotoDidSelect(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "BecomeAnExpert", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: ChooseInstagramPhotoViewController.className) as! ChooseInstagramPhotoViewController
        viewController.delegate = self
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func makeVideoDidSelect(_ sender: UIButton) {
        self.delegate?.didSelectMakeVideo()
    }

}

//MARK: - ChooseInstagramPhotoViewControllerDelegate
extension ConnectedInstargamProfileViewController : ChooseInstagramPhotoViewControllerDelegate {
    
    func didSelectImage(imageURL url: URL) {
        self.user.userImage = url
        self.updateProfileImageView(with: url)
    }
}
