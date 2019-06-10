//
//  AcceptStreamViewController.swift
//  HipWig
//
//  Created by Alexey on 1/31/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class AcceptStreamViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private var avatarImageView: UIImageView!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var gradientView: UIView!
    @IBOutlet private var acceptCallButton: UIButton!
    @IBOutlet private var declineCallButton: UIButton!
    
    //MARK: - Properties -
    public var call: IncomingCall = .empty
    
    private var opponent: User?
    private let api: RequestsManager = RequestsManager.manager
    private let callService: CallService = CallServiceImplementation.default
    private var timer: StartCallTimer = StartCallTimer()
    private let player: LoopingAudioPlayer = LoopingAudioPlayer()
    private let shared: SharedStorage = SharedStorageImplementation.default
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.adjustConstraints()
        self.userNameLabel.font = self.userNameLabel.font.adjusted
        
        self.timer.start(timeout: kIncomingCallTimeOut) { [weak self] in
            guard let `self` = self else { return }

            self.callService.dissmissCallView()
        }
        
        NotificationCenter.addWillEnterForegroundObserver { [weak self] in
            guard let `self` = self else { return }

            self.player.playCurrent(.ambient)
        }
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.player.play(name: "Opening", ext: "m4r", category: .ambient)
        self.api.fetchUser(id: self.call.opponent) { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let user):
                self.updateUserData(user: user)
            case .failure(let error):
                logger.log(error)
            }
        }
    } 

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.player.stop()
        self.player.destroy()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.gradientView.applyGradient(with: [UIColor.black.withAlphaComponent(0.4), .clear], gradient: .vertical)
        self.gradientView.layoutSubviews()
    }
    
    //MARK: - Private -
    private func updateUserData(user: User) {
        self.opponent = user
        self.userNameLabel.text = user.name
        self.avatarImageView.setImage(user.profileImage)
    }

    //MARK: - Actions -
    @IBAction private func declineCallSelected(_ sender: UIButton) {
        sender.disable()
        
        self.callService.declineCall(opponent: self.call.opponent) {
            sender.enable()
        }
    }

    @IBAction private func acceptCallSelected(_ sender: UIButton) {
        sender.disable()
        
        let stream = StreamData(avatar: self.opponent?.profileImage,
                                userName: self.opponent?.name,
                                userId: self.call.opponent,
                                session: self.call.session,
                                token: self.call.token)
        
        self.callService.acceptCall(stream: stream) {
            sender.enable()
        }
    }
}
