//
//  ResumeSessionViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/22/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ResumeSessionViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var indicatorView: UIActivityIndicatorView!
    
    //MARK: - Properties -
    private let api: RequestsManager = RequestsManager.manager
    private let account: AccountManager = AccountManager.manager
    private let featureFlagsService: FeatureFlagsService = FeatureFlagsServiceImplementation.defaut
    private let staticResourcesService: StaticResourcesService = StaticResourcesServiceImplementation.defaut
    private var afterNetworkDissapear = false
    private lazy var localization: Localization = Localization()
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reachability.add(reachabylityDelegate: self)
        
        NotificationCenter.addApplicationDidBecomeActiveObserver { [weak self] in
            guard let `self` = self else { return }
            
            if reachability.isNetworkReachable {
                if self.afterNetworkDissapear {
                    self.loadFeatureFlagListAndResumeSession()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        reachability.remove(reachabylityDelegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadFeatureFlagListAndResumeSession()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Private -
    private func loadFeatureFlagListAndResumeSession() {
        self.indicatorView.startAnimating()
        self.localization.load { [weak self] in
            guard let `self` = self else { return }
            
            self.featureFlagsService.fetchFlags { [weak self] error in
                guard let `self` = self else { return }
                
                if let error = error {
                    logger.log(error)
                    MainStoryboard.showLogin()
                } else {
                    self.staticResourcesService.fetchResourcesList { [weak self] in
                        guard let `self` = self else { return }
                        
                        self.resumeSession()
                    }
                }
            }
        }
    } 
    
    private func resumeSession() {
        switch self.account.tokenStatus {
        case .working:
            self.account.canResumeSession { canResume in
                if canResume {
                    self.fetchUserAndPerformRoute()
                } else {
                    MainStoryboard.showLogin()
                }
            }
        case .expired, .expireSoon:
            self.account.refreshUserTokens { [weak self] error in
                guard let `self` = self else { return }
                
                if let error = error {
                    logger.log(error)
                    MainStoryboard.showLogin()
                } else {
                    self.fetchUserAndPerformRoute()
                }
            }
        case .absent:
            MainStoryboard.showLogin()
        }
    }
    
    private func fetchUserAndPerformRoute() {
        self.api.unarchiveUserData()
        
        let lastRole = self.account.role
        if lastRole == .unknown {
            MainStoryboard.showLogin()
        } else {
            self.account.updateUser { [weak self] in
                guard let `self` = self else { return }
                
                let currentRole = self.account.role
                
                if currentRole != lastRole {
                    MainStoryboard.showLogin()
                } else {
                    SocketWrapper.wrapper.connect()
                    MainStoryboard.showMainScreen(useAnimation: false)
                }
            }
        }
    }
    
    override func service(_ service: ReachabilityService, didChangeNetworkState state: Bool) {
        if state {
            self.loadFeatureFlagListAndResumeSession()
            self.afterNetworkDissapear = false
        } else {
            self.afterNetworkDissapear = true
        }
    }
}
