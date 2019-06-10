//
//  StreamViewController.swift
//  HipWig
//
//  Created by Alexey on 1/31/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD

private typealias ChatInitClosure = () -> Void

struct StreamData {
    let avatar: String?
    let userName: String?
    
    let userId: String
    let session: String
    let token: String
}

class StreamViewController: BaseViewController {

    //MARK: - Interface -
    public var streamData: StreamData!

    //MARK: - Properties -
    private var call: Call?
    private let keyboardCoordinator = KeyboardCoordinator()
    private let account: AccountManager = AccountManager.manager
    private let socket = SocketWrapper.wrapper
    private let chatPresenseService: ChatPresenceService = ChatPresenceServiceImplementation.default
    private let callService: CallService = CallServiceImplementation.default
    private var recordTimeService: TimeRecordService = TimeRecordServiceImplementation()
    private var timeSaverService: TimeSaverService?
    private let api: RequestsManager = RequestsManager.manager
    private var chatID: String?
    private var messages: [ChatMessage] = []
    private var joinChatClosure: ChatInitClosure? = nil
    private let device: OTDefaultAudioDevice_OLD? = OTDefaultAudioDevice_OLD()
    private var tableBackgroundView: UIButton?
    private var animating: Bool = false
    private var shouldDisplayControls: Bool = true
    private var screenControls: [UIView] {
        return [
            self.opponentNameLabel,
            self.durationLabel,
            self.controlButtonStackView,
            self.ownerVideoView.cameraToggleBtn
        ]
    }
    private lazy var gesture: UITapGestureRecognizer = { .init(target: self, action: #selector(tap(_:))) } ()
    private var resignActiveDate: Date?
    
    //MARK: - Outlets -
    @IBOutlet private weak var opponentViewContainer: UIView!
    @IBOutlet private weak var opponentBigAvatar: UIImageView!
    @IBOutlet private weak var ownerVideoView: MyVideoView!
    @IBOutlet private weak var inputBar: ChatInputBar!
    @IBOutlet private weak var inputBarBottomPin: NSLayoutConstraint!
    @IBOutlet private weak var opponentNameLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var toggleSpeakerButton: StreamControlButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var controlButtonStackView: UIStackView!
    @IBOutlet private weak var tapContainerView: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    
    //MARK: - Life Cycle -
    deinit {
        self.call?.destroySession()
        self.call = nil
        self.recordTimeService.destroy()
        if let chatId = self.chatID, !chatId.isEmpty {
            self.socket.leave(chatID: chatId)
        }
        OTAudioDeviceManager.setAudioDevice(nil)
        
        self.socket.remove(delegate: self)
        print(#file + " " + #function)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.adjustConstraints()
        
        self.timeSaverService = TimeSaverServiceImplementation(timeRecorder: self.recordTimeService)
        self.recordTimeService.prepare()
        self.recordTimeService.addDelegate(delegate: self)
        
        self.timeSaverService?.set(expertId: self.streamData.userId)
        self.createAndJoinToChat()
        
        OTAudioDeviceManager.setAudioDevice(device)
        if let device = self.device, !device.isHeadsetPluggedIn() {
            self.toggleSpeakerButton.isSelected = false
        }
        
        self.setupUI()
        
        do {
            let call = Call(streamData: self.streamData)
            let publishVideoByDefault = self.account.role != .user

            try call.createSession(streamData: self.streamData)
            try call.createPublisher(publishVideo: publishVideoByDefault)

            self.ownerVideoView.setVideo(isOn: publishVideoByDefault)
            
            call.publisherDidCreateClosure = { [weak self] in
                guard let `self` = self else { return }
                guard let call = self.call else { return }
                
                self.ownerVideoView.setVideo(isOn: call.isPublishingVideo)
            }
            
            call.publisherDidConnectToStreamClosure = { [weak self] view in
                guard let `self` = self else { return }
                
                if let publisherView = view {
                    self.ownerVideoView.setupMyStream(view: publisherView)
                }
            }
            
            call.prevAudioStateClosure = { [weak self] in
                guard let `self` = self else { return false }
                
                return self.toggleSpeakerButton.isSelected
            }
            
            call.subscriberDidConnectClosure = { [weak self] view in
                guard let `self` = self else { return }
                
                if let subscriberView = view {
                    subscriberView.frame = self.opponentViewContainer.bounds
                    
                    self.opponentViewContainer.insertSubview(subscriberView, belowSubview: self.opponentBigAvatar)
                    self.opponentBigAvatar.isHidden = self.account.role == .user
                }
                
                if reachability.isNetworkReachable {
                    self.restoreVideoAndAudioAfterPause()
                    self.account.updateUser {
                        self.recordTimeService.start()
                    }
                }
            }
            
            call.subscriberVideoDisabledClosure = { [weak self] in
                guard let `self` = self else { return }
                
                self.opponentBigAvatar.isHidden = false
            }
            
            call.subscriberVideoEnabledClosure = { [weak self] in
                guard let `self` = self else { return }
                
                self.opponentBigAvatar.isHidden = true
            }
            
            call.subscriberDidReconnectClosure = { [weak self] in
                guard let `self` = self else { return }
                
                self.recordTimeService.pause(reason: .streamDestroy)
            }
            
            call.publisherStreamDidDestroyClosure = { [weak self] _ in
                guard let `self` = self else { return }
                
                self.recordTimeService.pause(reason: .streamDestroy)
            }
            
            call.sessionDidConnectionDestroyClosure = { [weak self] in
                guard let `self` = self else { return }
                
                self.pauseTimerAndEndCall()
            }
            
            self.call = call
            
        } catch let error {
            logger.log(error)
        }

        self.opponentBigAvatar.setImage(self.streamData.avatar ?? "")
        
        if self.streamData.userName == nil {
            self.fetchUser(id: self.streamData.userId)
        }
        
        NotificationCenter.addEndCallObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.recordTimeService.destroy()
        }
        
        NotificationCenter.addAVInteraptionObserver { [weak self] interaption in
            guard let `self` = self else { return }
            guard let interaption = interaption else { return }
            
            if interaption.type == .began {
                self.recordTimeService.pause(reason: .interaption)
            } else if interaption.type == .ended {
                self.recordTimeService.resume()
            }
        }
        
        NotificationCenter.addEndCallObserver { [weak self] in
            guard let `self` = self else { return }
         
            self.recordTimeService.pause(reason: .callEnded)
        }
        
        NotificationCenter.addPauseCallObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.recordTimeService.pause(reason: .callPause)
            self.setVideoPublishing(false)
            
            if let view = self.callService.window?.rootViewController?.view {
                let closeButtonFrame = view.convert(self.controlButtonStackView.frame, to: view)
                
                ModalStoryboard.showPauseCall(on: self.callService.window, closeButtonFrame: closeButtonFrame) { [weak self] in
                    guard let `self` = self else { return }

                    self.pauseTimerAndEndCall()
                }
            }
        }
        
        NotificationCenter.addWillDestroyCallWindowObserver { [weak self] in
            guard let `self` = self else { return }

            ModalStoryboard.hidePauseCall(on: self.callService.window, animated: false)
        }
        
        NotificationCenter.addResumeCallObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.recordTimeService.resume()
            self.restoreVideoAndAudioAfterPause()
            
            ModalStoryboard.hidePauseCall(on: self.callService.window)
        }
        
        
        NotificationCenter.addApplicationResignActiveObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.resignActiveDate = Date()
        }
        
        NotificationCenter.addWillEnterForegroundObserver { [weak self] in
            guard let `self` = self else { return }
            
            let updateChatlistClosure: ([ChatMessage]) -> Void = { newMessages in
                if self.messages.count > 0 {
                    self.messages.insert(contentsOf: newMessages, at: 0)
                } else {
                    self.messages += newMessages
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
            if let lastMessage = self.messages.last {
                self.api.getChatHistory(lastMessage.senderId, lastMesage: lastMessage.id) { result in
                    switch result {
                    case .success(let response):
                        updateChatlistClosure(response.data)
                    case .failure(let error):
                        logger.log(error)
                    }
                }
            } else if let date = self.resignActiveDate, let chatId = self.chatID {
                self.api.getChatHistory(chatId, date: date) { result in
                    switch result {
                    case .success(let response):
                        updateChatlistClosure(response.data)
                    case .failure(let error):
                        logger.log(error)
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.keyboardCoordinator.subscribeForKeyboardEvents()

        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.keyboardCoordinator.unsubscribeFromKeyboardEvents()

        UIApplication.shared.isIdleTimerDisabled = false

        self.ownerVideoView.clean()
        self.socket.remove(delegate: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.tableBackgroundView?.frame = self.tableView.bounds
    }
    
    //MARK: - Private -
    private func fetchUser(id: String) {
        self.api.fetchUser(id: id) { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let user):
                self.opponentNameLabel.text = user.name
                self.opponentBigAvatar.setImage(user.profileImage)
            case .failure(let error):
                logger.log(error)
            }
        }
    }
    
    private func createAndJoinToChat() {
        
        self.chatPresenseService.setLoadingChat()
        self.socket.add(delegate: self)
        
        var userID: String?
        var expertID: String?
        
        if self.account.role == .expert {
            userID = self.streamData.userId
        } else {
            expertID = self.streamData.userId
        }
        
        self.api.createChat(userID: userID, expertID: expertID) { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let id):
                self.chatID = id
                self.socket.join(chatID: id)
                
                self.tableView.reloadData()
                
            case .failure(let error):
                logger.log(error)
            }
        }
    }
    
    private func pauseTimerAndEndCall() {
        self.pauseTimerAndSendTime()
        self.callService.endCall(opponent: self.streamData.userId, removeCallWindow: true, completion: nil)
    }
    
    private func setupUI() {
        self.ownerVideoView.delegate = self
        self.opponentNameLabel.text = self.streamData.userName
        
        self.tableView.registerNib(with: StreamMessageReceiveCell.self)
        self.tableView.registerNib(with: StreamMessageSendCell.self)
        
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200.adjusted
        self.tableView.allowsSelection = false
        
        self.tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        self.inputBar.delegate = self
        self.inputBar.backgroundColor = .clear
        
        self.tableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        
        if self.tableBackgroundView == nil {
            self.tableBackgroundView = UIButton(frame: .zero)
            self.tableBackgroundView?.addTarget(self, action: #selector(animateControls), for: .touchUpInside)
            
            self.tableView.backgroundView = self.tableBackgroundView
        }
        
        self.tapContainerView.addGestureRecognizer(self.gesture)
        
        self.keyboardCoordinator.update(with: self.view)
        self.keyboardCoordinator.willShowKeyboardHandler = { [weak self] value in
            guard let `self` = self else { return }
            
            self.inputBarBottomPin.constant = value
            if !self.messages.isEmpty {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .none, animated: true)
            }
        }
        
        self.keyboardCoordinator.willHideKeyboardHandler = { [weak self] in
            self?.inputBarBottomPin.constant = 0.0
        }
        
        self.keyboardCoordinator.updateLayoutHandler = { [weak self] in
            self?.updateEntireLayout()
        }
    }

    
    @objc private func tap(_ sender: UITapGestureRecognizer) {
        self.animateControls()
    }
    
    @objc private func animateControls() {
        if self.animating {
            return
        }
        
        self.shouldDisplayControls.toggle()
        let alpha: CGFloat = self.shouldDisplayControls ? 1.0 : 0.0
        
        self.animating = true
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.screenControls.forEach{ view in
                view.alpha = alpha
            }
        }) { [weak self] _ in
            self?.animating = false
        }
    }

    private func toggleSpeaker(_ state: Bool) {
        let port: AVAudioSession.PortOverride = state ? .speaker : .none

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: .allowBluetooth)
            try audioSession.setActive(true)

            try audioSession.overrideOutputAudioPort(port)

        } catch {
            logger.log(error)
        }
    }

    private func pauseTimerAndSendTime() {
        self.recordTimeService.pause(reason: .callEnded)
        self.timeSaverService?.updateCallTime()
    }
    
    private func updateEntireLayout() {
        self.inputBar.updateLayout()
        
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.inputBar.textView.snapScrollPositionToInput = true
            self?.view.layoutIfNeeded()
        }) { [weak self] completed in
            self?.inputBar.textView.snapScrollPositionToInput = false
        }
    }
    
    private func updateTimerLabel(with timeInterval: TimeInterval) {
        self.durationLabel.text = String(format: "%02i:%02i", timeInterval.minutes, timeInterval.seconds)
    }

    private func insert(newMessage message: ChatMessage) {
        self.messages.insert(message, at: 0)

        let rowAnimation: UITableView.RowAnimation = .bottom
        let indexPaths = [IndexPath(row: 0, section: 0)]

        self.tableView.beginUpdates()
        self.tableView.insertRows(at: indexPaths, with: rowAnimation)
        self.tableView.endUpdates()
        
        self.tableView.reloadRows(at: indexPaths, with: .automatic)

        self.tableView.setContentOffset(.zero, animated: false)
    }
    
    //MARK: - Actions -
    @IBAction private func endCallSelected(_ sender: UIButton) {
        sender.disable()
        
        self.pauseTimerAndEndCall()
    }
    
    @IBAction private func disableMicriphoneSelected(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        self.call?.set(publishAudio: !sender.isSelected)
    }
    
    @IBAction private func disableAudioOutputSelected(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @IBAction private func changeAudioOutputRouteSelected(_ sender: UIButton) {
        DispatchQueue.main.async {
            sender.isSelected.toggle()
            
            self.toggleSpeaker(!sender.isSelected)
        }
    }
}

// MARK: - MyVideoViewDelegate
extension StreamViewController: MyVideoViewDelegate {
    
    func view(_ view: MyVideoView, changePublishVideState state: Bool) {
        if let call = self.call {
            call.set(publishVideo: state)
        }
    }

    func onMyCameraPositionToggle() {
        if let call = self.call {
            call.toggleCamera()
        }
    }
}

//MARK: - UITableViewDelegate
extension StreamViewController: UITableViewDelegate {
    
}

//MARK: - UITableViewDataSource
extension StreamViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = self.messages[indexPath.row]
        
        let cellSelectedClosure = { [weak self] in
            guard let `self` = self else { return }
            
            self.animateControls()
        }
        
        var cellToReturn: UITableViewCell
        if self.streamData.userId == message.senderId {
            let cell: StreamMessageReceiveCell = tableView.dequeueReusableCell(indexPath: indexPath)
            
            cell.setup(with: message)
            cell.cellSelectedClosure = cellSelectedClosure
            cell.urlSelectedClosure = { [weak self] url in
                guard let `self` = self else { return }
                
                ModalStoryboard.showWEBView(with: url, from: self)
            }
            
            cellToReturn = cell
        } else {
            let cell: StreamMessageSendCell = tableView.dequeueReusableCell(indexPath: indexPath)
            
            cell.setup(with: message)
            cell.cellSelectedClosure = cellSelectedClosure
            cell.urlSelectedClosure = { [weak self] url in
                guard let `self` = self else { return }
                
                ModalStoryboard.showWEBView(with: url, from: self)
            }
            
            cellToReturn = cell
        }
        
        cellToReturn.transform = self.tableView.transform
        
        return cellToReturn
    }
}

//MARK: - ChatInputBarDelegate
extension StreamViewController: ChatInputBarDelegate {
    
    func onTextChanged(with text: String) {
        let enteredText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let color = enteredText.isEmpty ? UIColor(red: 69, green: 79, blue: 99) : selectedColor
        
        self.inputBar.tintColor = color
    }
    
    func onSendButtonAction(text: String) {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if message.isEmpty {
            return
        }
        
        self.sendMessageSafe(message: message, to: self.streamData.userId)
        
        self.inputBar.clear()
    }

    private func sendMessageSafe(message: String, to opponent: String) {
        if let userID = self.account.myUserID {
            if let chatId = self.chatID, !chatId.isEmpty {
                if self.socket.isJoinedToChat && self.socket.status == .connected {
                    self.socket.sendMessage(chatID: chatId, receiver: opponent, sender: userID, message: message)
                } else {
                    self.joinChatClosure = { [weak self] in
                        guard let `self` = self else { return }
                        
                        self.socket.sendMessage(chatID: chatId, receiver: opponent, sender: userID, message: message)
                    }
                    
                    if self.socket.status != .connected {
                        self.socket.connect()
                    } else {
                        self.joinToChat(with: chatId)
                    }
                }
            } else {
                self.api.createChat(userID: nil, expertID: opponent) { [weak self] response in
                    guard let `self` = self else { return }
                    
                    switch response {
                    case .success(let chatId):
                        self.joinChatClosure = { [weak self] in
                            guard let `self` = self else { return }
                            
                            self.socket.sendMessage(chatID: chatId, receiver: opponent, sender: userID, message: message)
                        }
                        
                        self.joinToChat(with: chatId)
                    case .failure(let error):
                        logger.log(error)
                        SVProgressHUD.showError(withStatus: "Can't send message with other user (Chat create error)")
                    }
                }
            }
        } else {
            SVProgressHUD.showError(withStatus: "Somethind bad had happend! Try to relogin")
        }
    }
    
    private func joinToChat(with chatId: String) {
        self.chatID = chatId
        self.socket.join(chatID: chatId)
        
        self.view.layoutIfNeeded()
        self.tableView.reloadData()
    }
}

//MARK: - SocketWrapperDelegate
extension StreamViewController: SocketWrapperDelegate { 
    
    func soket(_ socket: SocketWrapper, didShangeStatus status: WrapperStatus) {
        
    }
     
    func soket(_ socket: SocketWrapper, didReceiveMessage message: ChatMessage) {
        if let chatId = self.chatID, message.senderId == self.streamData.userId {
            if let userID = self.account.myUserID {
                self.socket.readMessage(chatID: chatId, myID: userID, lastMessageID: message.id)
            }
        }
        
        self.insert(newMessage: message)
    }

    func onDisconnect() {
        
    }

    func onConnect() {
        guard let chatId = self.chatID, !chatId.isEmpty else {
            print("[Chat]: chat id is empty")
            return
        }
        
        self.socket.join(chatID: chatId)
    }
    
    func soket(_ socket: SocketWrapper, didJoinToChat id: String?) {
        if let joinChatClosure = self.joinChatClosure {
            joinChatClosure()
            self.joinChatClosure = nil
        }
    }
    
    func soket(_ socket: SocketWrapper, didLeaveChat id: String?) {
        
    }
}

//MARK: - TimeRecordServiceDelegate
extension StreamViewController: TimeRecordServiceDelegate {
    
    private func setVideoPublishing(_ allowPublishing: Bool, savePreviousState: Bool = true) {
        guard let call = self.call else { return }
        
        call.set(publishAudio: allowPublishing)
        call.set(publishVideo: allowPublishing)
    }
    
    private func restoreVideoAndAudioAfterPause() {
        guard let call = self.call else { return }
        
        call.set(publishAudio: call.isPublishingAudio)
        call.set(publishVideo: self.ownerVideoView.videoToggleBtn.isSelected)
    }
    
    func service(_ service: TimeRecordService, didReachTimeThreshold threshold: CallThreshold) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            //FIXME: !!!!!!
            self.toggleSpeaker(self.toggleSpeakerButton.isSelected)
            
            if threshold == .zero {
                service.pause(reason: .callPause)
                
                self.setVideoPublishing(false)
                self.api.pauseCall(receiver: self.streamData.userId)
            } else {
                self.timeSaverService?.updateCallTime()
            }
            
            let caption: String? = threshold == .zero ? "stream.paused_call_title".localized : nil
            
            MainStoryboard.showAddCallCreditsPopup(callThreshold: threshold, callCaption: caption, whileInCallingState: true) { [weak self] haveBoughtMinutes in
                guard let `self` = self else { return }
                
                if haveBoughtMinutes {
                    SVProgressHUD.show()
                    
                    self.account.updateUser { [weak self] in
                        guard let `self` = self else { return }
                        
                        SVProgressHUD.dismiss()
                        
                        if service.hasAvailableTime {
                            self.restoreVideoAndAudioAfterPause()
                            
                            service.resume()
                        }
                    }
                } else {
                    if threshold == .zero {
                        self.pauseTimerAndEndCall()
                    } else {
                        self.restoreVideoAndAudioAfterPause()
                    }
                }
                
                self.api.resumeCall(receiver: self.streamData.userId)
            }
            
//            let caption: String = threshold == .zero ? "Insufficient Coins" : "Coins almost gone"
//            let details: String = threshold == .zero ? "Recharge to start video chat." : "Recharge before they run out"
//
//            ModalStoryboard.showAddCallCreditsPopup(title: caption, details: details) { haveBoughtMinutes in
//                if haveBoughtMinutes {
//                    SVProgressHUD.show()
//
//                    self.account.updateUser {
//                        SVProgressHUD.dismiss()
//
//                        if service.hasAvailableTime {
//                            self.restoreVideoAndAudioAfterPause()
//
//                            service.resume()
//                        }
//                    }
//                } else {
//                    if threshold == .zero {
//                        self.pauseTimerAndEndCall()
//                    } else {
//                        self.restoreVideoAndAudioAfterPause()
//                    }
//                }
//
//                self.api.resumeCall(opponentID: self.streamData.userId)
//            }
        }
    }
    
    func service(_ service: TimeRecordService, didChangeTimeInterval interval: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if UIApplication.shared.applicationState == .active {
                self.updateTimerLabel(with: interval)
            }
        }
    }
}
