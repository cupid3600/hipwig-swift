//
//  BaseViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/1/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD
import SafariServices

class BaseViewController: UIViewController, NetworkReachabilityDelegate {

    //MARK: - Outlets -
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var navigationTitleLabel: UILabel!
    
    private let api: RequestsManager = RequestsManager.manager
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()

        self.edgesForExtendedLayout = .all
        
        self.navigationTitleLabel?.font = self.navigationTitleLabel?.font.adjusted
        self.backButton?.titleLabel?.font = self.backButton?.titleLabel?.font?.adjusted
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if reachability.isNetworkReachable {
            if let recipe = UIApplication.shared.recipe {
                if ProductServiceImplementation.hasUploadRecipeTaskForCurrentUser {
                    self.api.uploadReceipt(recipe: recipe) { error in
                        if error == nil {
                            ProductServiceImplementation.removeUploadRecipeTaskForCurrentUser()
                        } else {
                            ProductServiceImplementation.updateUploadRecipeStatus(needUpload: true)
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if SVProgressHUD.isVisible() {
            SVProgressHUD.dismiss()
        }
    }
    
    //MARK: - Actions -
    @IBAction func backDidSelect(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.view.backgroundColor = textColor3
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func service(_ service: ReachabilityService, didChangeNetworkState state: Bool) {
        
    }
}
