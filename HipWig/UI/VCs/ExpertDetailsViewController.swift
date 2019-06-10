//
//  ExpertDetailsViewController.swift
//  HipWig
//
//  Created by Alexey on 1/20/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit 
import AVFoundation
import SVProgressHUD
import Kingfisher
import ASPVideoPlayer
import Alamofire

class ExpertDetailsViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private var expertImage: UIImageView!
    @IBOutlet private var expertNameLabel: UILabel!
    @IBOutlet private var callButton: UIButton!
    @IBOutlet private var messageButton: UIButton!
    @IBOutlet private var unblockButton: UIButton!
    @IBOutlet private var infoView: ProfileInfoView!
    @IBOutlet private var expertListView: ProfileExpertListView!
    @IBOutlet private var audioToggleButton: UIButton!
    @IBOutlet private var muteAudioView: UIView!
    @IBOutlet private var videoPlayerView: ASPVideoPlayerView!
    @IBOutlet private var topGradientView: UIImageView!

    //MARK: - Interface -
    public var expert: User!
    
    //MARK: - Properties -
    private let callService: CallService = CallServiceImplementation.default
    private let flags: ExpertDetailsFeatureFlagCategory = ExpertDetailsFeatureFlagCategoryImplementation.default
    private var firstCallView: FirstCallView?
    private let videoProvider = VideosProvider.provider
    private let api = RequestsManager.manager
    private let account: AccountManager = AccountManager.manager
    private var downloadVideoRequest: DownloadRequest?
    private var buttons: [UIButton] {
        return [
            self.callButton,
            self.messageButton,
            self.unblockButton,
            self.audioToggleButton,
        ]
    } 
    private let storage: ExpertLocalStorage = ExpertLocalStorageImplementation.default
    var videoStopped: Bool = true {
        didSet {
            self.videoPlayerView?.isHidden = videoStopped
        }
    }
    
    var soundMuted: Bool = true {
        didSet {
            if self.callService.isCallingState || UIApplication.topViewController() != self {
                self.audioToggleButton?.isSelected = true
                self.videoPlayerView?.volume = 0
            } else {
                self.audioToggleButton?.isSelected = soundMuted
                self.videoPlayerView?.volume = soundMuted ? 0 : 1
            }
        }
    }
    
    private var mutedByUser: Bool?
    private var prevMutedState: Bool?
    private var savedPlayerProgress: Double?
    private let permissions: PermissionService = PermissionServiceImplementation()
    
    //MARK: - Life Cycle -
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        reachability.remove(reachabylityDelegate: self)
        self.cancelLastOperationsAndMuteVideo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.adjustConstraints()
        
        self.unblockButton.layer.cornerRadius = 8.adjusted
        self.unblockButton.isHidden = true
        self.callButton.layer.cornerRadius = 8.adjusted
        self.messageButton.layer.cornerRadius = 8.adjusted
        self.muteAudioView.backgroundColor = textColor3.withAlphaComponent(0.5)
        self.topGradientView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        self.soundMuted = true
        
        self.audioToggleButton.setTitle("expert_details.mute_button.unmute".localized, for: .selected)
        self.audioToggleButton.setTitle("expert_details.mute_button.mute".localized, for: .normal)
        
        self.expertNameLabel.font = self.expertNameLabel.font.adjusted
        self.buttons.forEach { $0.titleLabel?.font = $0.titleLabel?.font.adjusted }

        self.expertListView.setup(experts: self.storage.experts, currentID: self.expert.id)
        self.expertListView.delegate = self
 
        self.videoPlayerView.startPlayingWhenReady = true
        self.videoPlayerView.shouldLoop = true
        self.videoPlayerView.startedVideo = { [weak self] in
            guard let `self` = self else { return }
            
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
                try audioSession.setActive(true)
            } catch {
                logger.log(error)
            }
            
            if let progress = self.savedPlayerProgress, progress > 0.0 {
                self.savedPlayerProgress = nil
                self.videoPlayerView.seek(progress)
            }
        }
        
        if !UserDefaults.firstCallViewShown {
            UserDefaults.setFirstCallViewAsShown()
            
            self.firstCallView = FirstCallView.show(source: self.infoView)
        }
        
        NotificationCenter.addDisplayCallWindowObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.videoPlayerView.stopVideo()
        }
        
        NotificationCenter.addDestroyCallWindowObserver { [weak self] in
            guard let `self` = self else { return }
            
            if UIApplication.topViewController() == self {
                self.updateView()
            }
        }
        
        NotificationCenter.addApplicationWillEnterForegroundObserver { [weak self] in
            guard let `self` = self else { return }

            if UIApplication.topViewController() == self && !self.callService.isCallingState {
                if reachability.isNetworkReachable {
                    self.restoreMuteButtonState()
                    self.loadExpertData(useUpdateVideoAnimation: false)
                }
            }
        }

        NotificationCenter.addApplicationDidEnterBackgroundObserver { [weak self] in
            guard let `self` = self else { return }

            self.savedPlayerProgress = self.videoPlayerView.currentTime / self.videoPlayerView.videoLength
            self.videoPlayerView.pauseVideo()
            self.cancelLastOperationsAndMuteVideo()
        }
        
        NotificationCenter.addBlockUserObserver { [weak self] sender in
            guard let `self` = self else { return }
            
            if self.expert.id == sender {
                if UIApplication.topViewController() == self && !self.callService.isCallingState {
                    if reachability.isNetworkReachable {
                        self.restoreMuteButtonState()
                        self.loadExpertData(useUpdateVideoAnimation: false)
                    }
                }
            }
        }
        
        NotificationCenter.addUnBlockUserObserver { [weak self] sender in
            guard let `self` = self else { return }
            
            if self.expert.id == sender {
                if UIApplication.topViewController() == self && !self.callService.isCallingState {
                    if reachability.isNetworkReachable {
                        self.restoreMuteButtonState()
                        self.loadExpertData(useUpdateVideoAnimation: false)
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reachability.add(reachabylityDelegate: self)
        
        if reachability.isNetworkReachable {
            self.loadExpertData()
        } else {
            self.updateView()
        }
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Private -
    private func cancelLastOperationsAndMuteVideo() {
        self.muteVideo()
        self.downloadVideoRequest?.cancel()
    }
    
    private func muteVideo() {
        self.prevMutedState = self.prevMutedState ?? self.soundMuted
        self.soundMuted = true
    }
    
    private func updateView(animateVideoView: Bool = true) {
        self.updateView(withFlags: self.flags)
        self.updateView(withUser: self.expert)
        self.restoreMuteButtonState()
        self.updateVideoPlayer(animateVideoView: animateVideoView)
    }
    
    override func service(_ service: ReachabilityService, didChangeNetworkState state: Bool) {
        if state {
            self.loadExpertData()
        } else {
            self.updateView()
        }
    }
    
    //MARK: - Private -
    private func loadExpertData(useUpdateVideoAnimation: Bool = true) {
        self.infoView?.isLoadign = true
        self.fetchExpert(with: self.expert.id) { [weak self] in
            self?.infoView?.isLoadign = false
            self?.updateView(animateVideoView: useUpdateVideoAnimation)
        }
    }

    private func updateView(withFlags flags: ExpertDetailsFeatureFlagCategory) {
        if self.expert.youBlocked || self.expert.youWasBlocked {
            self.callButton?.isHidden = true
            self.messageButton?.isHidden = true
        } else {
            self.callButton?.isHidden = !flags.expertCallEnabled
            self.messageButton?.isHidden = !flags.expertChatEnabled
        }

        self.unblockButton?.isHidden = !self.expert.youBlocked
    }
    
    private func updateVideoPlayer(animateVideoView: Bool) {
        self.videoStopped = true
        self.expertImage?.image = nil
        self.muteAudioView?.isHidden = true
        
        if let videoURL = self.expert.expert?.profileVideo {
            let res = self.videoProvider.hasVideoFile(with: videoURL)
            
            if res.localVideoExist {
                self.loadVideo(url: videoURL, animate: animateVideoView)
            } else {
                self.expertImage?.setImage(self.expert.profileImage)
                if animateVideoView {
                    self.animateProfileImage()
                }
                
                if reachability.isNetworkReachable {
                    self.loadVideo(url: videoURL, animate: animateVideoView)
                }
            }
        } else {
            self.expertImage?.setImage(self.expert.profileImage)
            
            if animateVideoView {
                self.animateProfileImage()
            }
        }
    }
    
    private func loadVideo(url videoURL: String, animate: Bool) {
        self.downloadVideoRequest = self.videoProvider.videoFile(videoURL: videoURL) { [weak self] videoUrl in
            
            guard let `self` = self else { return }

            if let url = videoUrl {
                if let existedURL = self.videoPlayerView?.videoURL {
                    if existedURL.absoluteString == url.absoluteString {
                        let progress = self.videoPlayerView.currentTime / self.videoPlayerView.videoLength
                        if progress <= 0.0 {
                            self.videoPlayerView?.videoURL = url
                        } else {
                            self.savedPlayerProgress = progress
                            self.videoPlayerView.playVideo()
                        }
                    } else {
                        self.videoPlayerView?.videoURL = url
                    }
                } else {
                    self.videoPlayerView?.videoURL = url
                }
                
                if animate {
                    self.animateVideoView()
                }
            } else {
                self.expertImage?.setImage(self.expert.profileImage)
            }
            
            self.videoStopped = videoUrl == nil
            self.muteAudioView?.isHidden = videoUrl == nil
        }
    }
    
    private func animateProfileImage() {
        self.expertImage?.alpha = 0.0
        
        UIView.animate(withDuration: 1.0) {
            self.expertImage?.alpha = 1.0
        }
    }
    
    private func animateVideoView() {
        self.videoPlayerView?.alpha = 0.0
        
        UIView.animate(withDuration: 1.0) {
            self.videoPlayerView?.alpha = 1.0
        }
    }
    
    private func restoreMuteButtonState() {
        if let mutedByUser = self.mutedByUser {
            self.soundMuted = mutedByUser
        } else {
            if let prevState = self.prevMutedState {
                self.soundMuted = prevState
            } else {
                self.soundMuted = !self.flags.soundEnabled
            }
        }
    }
    
    private func fetchExpert(with id: String, completion: @escaping () -> Void) {
        self.api.fetchUser(id: id) { [weak self] result in
            switch result {
            case .success(let user):
                self?.expert = user
            case .failure(let error):
                logger.log(error)
            }
            
            completion()
        }
    }

    private func updateView(withUser user: User) {
        self.expertNameLabel?.text = user.name
        self.infoView?.setup(user: user)
        
        if user.isAvailable {
            self.callButton.enable()
        } else {
            self.callButton.disable()
        }
    }
    
    //MARK: - Actions -
    @IBAction private func conversationSelected(_ sender: UIButton) {
        self.cancelLastOperationsAndMuteVideo()
        
        let action: Action = .sendMessage(to: self.expert)
        self.permissions.check(for: action) { isAvailableToSent in
            if isAvailableToSent {
                if let source = UIApplication.topViewController()?.navigationController {
                    MainStoryboard.showConversation(from: source, with: self.expert)
                    analytics.log(.open(screen: .conversation(user: self.expert.name)))
                }
            } else {
                self.restoreMuteButtonState()
            }
        }
    }
    
    @IBAction private func unblockSelected(_ sender: UIButton) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        
        self.api.unblock(userID: self.expert.id) { [weak self] error in
            SVProgressHUD.dismiss()
            
            if let error = error {
                logger.log(error)
            } else {
                self?.loadExpertData()
            }
        }
        
        analytics.log(.unblock(user: self.expert.id)) 
    }

    @IBAction private func callSelected(_ sender: UIButton) {
        self.cancelLastOperationsAndMuteVideo()
        
        sender.disable()
        
        self.callService.call(to: self.expert) { [weak self] in
            guard let `self` = self else { return }
            
            self.restoreMuteButtonState()
            sender.enable()
        }
    }
    
    @IBAction private func toggleAudioSelected(_ sender: UIButton) {
        self.soundMuted.toggle()
        self.mutedByUser = self.soundMuted
        
        analytics.log(.sound(muted: self.soundMuted))
    }
}

//MARK: - ProfileExpertListViewDelegate
extension ExpertDetailsViewController: ProfileExpertListViewDelegate {
    
    func view(_ view: ProfileExpertListView, didSelectExpert expert: User) {
        self.expert = expert
        
        self.videoPlayerView.stopVideo()
        self.cancelLastOperationsAndMuteVideo()
        
        if reachability.isNetworkReachable {
            self.loadExpertData()
        } else {
            self.updateView()
        }
    }
}
