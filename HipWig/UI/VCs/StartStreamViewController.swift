//
//  VideoChatViewController.swift
//  HipWig
//
//  Created by Alexey on 1/30/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class StartStreamViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private var avatar: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var callingBackgroundView: UIView?
    @IBOutlet private var pulsingView: PulseView!
    @IBOutlet private var unansweredBackgroundView: UIView?
    @IBOutlet private var repeatCallButton: UIButton!
    @IBOutlet private var exitButton: UIButton!
    @IBOutlet private var noAnswerTextLabel: UILabel!
    @IBOutlet private var callingTextLabel: UILabel!

    //MARK: - Interface -
    public var opponent: User!
    
    //MARK: - Properties -
    private var timer: StartCallTimer = StartCallTimer()
    private let account: AccountManager = AccountManager.manager
    private let api: RequestsManager = RequestsManager.manager
    private let callService: CallService = CallServiceImplementation.default
    private let socket: SocketWrapper = SocketWrapper.wrapper
    private var isCalling: Bool = true {
        didSet {
            self.callingBackgroundView?.isHidden = !isCalling
            self.unansweredBackgroundView?.isHidden = isCalling
            
            if !isCalling {
                self.callService.resetPrevSession()
            }
        }
    }
    private var player: LoopingAudioPlayer = LoopingAudioPlayer()
    private var chatID: String?
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.adjustConstraints()
        
        self.socket.add(delegate: self)
        self.setupView(with: self.opponent)
        self.setupTextLabel()
        
        NotificationCenter.addApplicationDidBecomeActiveObserver { [weak self] in
            guard let strongSelf = self else { return }

            if strongSelf.isCalling {
                strongSelf.pulsingView.start()
                strongSelf.view.layoutIfNeeded()

                strongSelf.player.playCurrent()
            }
        }
        
        NotificationCenter.addDeclineCallObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.player.stop()
            
            self.isCalling = false
        }
        
        self.player.play(name: "ringing", ext: "wav", volume: 0.5)
        self.timer.start(timeout: kOutgoingCallTimeOut) { [weak self] in
            guard let `self` = self else { return }
            
            self.isCalling = false
            self.player.stop()
            
            self.callService.endCall(opponent: self.opponent.id, removeCallWindow: false, completion: nil)
        }
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pulsingView.start() 
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.pulsingView.layoutIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.socket.remove(delegate: self)
        self.timer.stop()
        self.player.destroy()
        
        if let id = self.chatID {
            SocketWrapper.wrapper.leave(chatID: id)
        }
    }
    
    //MARK: - Actions -
    @IBAction private func endCallSelected(_ sender: UIButton) {
        sender.disable()
        
//        self.callService.checkForCallorDissmissCallWindow { [weak self] hasActiveCall in
//            guard let `self` = self else { return }
//
//            if hasActiveCall {
//
//            } else {
                self.callService.endCall(opponent: self.opponent.id, removeCallWindow: true, completion: nil)
//            }
//        }
    }
    
    @IBAction private func tryAnotherExpertSelected(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.callService.dissmissCallView()
            
            if self.account.role == .user {
                MainStoryboard.showExpertListIfAvailable()
            } else {
                MainStoryboard.showChatListIfAvailable()
            }
        }
    }
    
    @IBAction private func callMeBackSelected(_ sender: UIButton) {
        sender.disable()
        
        DispatchQueue.main.async {
            if reachability.isNetworkReachable {
                if let userID = self.account.myUserID {
                    self.api.createChat(userID: userID, expertID: self.opponent.id) { [weak self] result in
                        guard let `self` = self else { return }
                        
                        switch result {
                        case .success(let id):
                            self.chatID = id
                            self.socket.join(chatID: id)
                        case .failure(let error):
                            logger.log(error)
                        }
                    }
                }
            } else {
                ModalStoryboard.showUnavailableNetwork()
            }
        }
    }

    //MARK: - Private -
    private func setupTextLabel() {
        let exitButtonTitle = self.account.role == .expert ? "start_call.try_another_client" : "start_call.try_another_expert"
        self.exitButton.setTitle(exitButtonTitle.localized, for: .normal)
        
        self.callingTextLabel.font = self.callingTextLabel.font.adjusted
        self.noAnswerTextLabel.font = self.noAnswerTextLabel.font.adjusted
        self.nameLabel.font = self.nameLabel.font.adjusted
        self.repeatCallButton.titleLabel?.font = self.repeatCallButton.titleLabel?.font?.adjusted
        self.exitButton.titleLabel?.font = self.exitButton.titleLabel?.font?.adjusted
        self.exitButton.setTitle(self.exitButton.title(for: .normal), for: .highlighted)
        self.repeatCallButton.setTitle(self.repeatCallButton.title(for: .normal), for: .highlighted)
    }
    
    private func setupView(with opponent: User) {
        self.isCalling = true
        
        self.nameLabel.text = opponent.name
        self.avatar.setImage(opponent.profileImage)
    }
}

//MARK: - SocketWrapperDelegate -
extension StartStreamViewController : SocketWrapperDelegate {
    
    func soket(_ socket: SocketWrapper, didReceiveMessage message: ChatMessage) {
        
    }
    
    func onConnect() {
        if let id = self.chatID {
            self.socket.join(chatID: id)
        }
    }
    
    func onDisconnect() {
        
    } 
    
    func soket(_ socket: SocketWrapper, didShangeStatus status: WrapperStatus) {
        
    }
    
    func soket(_ socket: SocketWrapper, didJoinToChat id: String?) {
        if self.chatID == id && id != nil {
            let receiver = self.opponent.id
            if let userID = self.account.myUserID {
                let message = "start_call.call_me_back_message".localized
                SocketWrapper.wrapper.sendMessage(chatID: id!, receiver: receiver, sender: userID, message: message)
                
                self.callService.dissmissCallView()
            }
        }
    }
    
    func soket(_ socket: SocketWrapper, didLeaveChat id: String?) {
        
    }
}
