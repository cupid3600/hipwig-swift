//
//  ConversationViewController.swift
//  HipWig
//
//  Created by Alexey on 1/23/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD
import AVFoundation 

private typealias ChatInitClosure = () -> Void
private typealias CreateChatCompletionClosure = (Bool) -> Void

class ConversationViewController: BaseViewController {

    //MARK: - Properties -
    public var opponentId: String!
    
    private var opponent: User?
    private let socket = SocketWrapper.wrapper
    private var chatID: String?
    
    private var messages: [ChatMessage] = []
    private var pagination: Pagination = .default
    private var isLastMessageReaded = false
    private let keyboardCoordinator = KeyboardCoordinator()
    private var player: AVAudioPlayer?
    private let api: RequestsManager = RequestsManager.manager
    private let account: AccountManager = AccountManager.manager
    private let chatPresenseService: ChatPresenceService = ChatPresenceServiceImplementation.default
    private var isFetchingMessages: Bool = false
    private lazy var callService = CallServiceImplementation()
    private let messageService: MessageService = MessageServiceImplementation.default
    
    private var chatIsBlocked: Bool {
        if let opponent = self.opponent {
            return opponent.youBlocked || opponent.youWasBlocked
        } else {
            return true
        }
    }
    
    private var allowUnblock: Bool {
        if let opponent = self.opponent {
            return opponent.youBlocked
        } else {
            return false
        }
    }
    
    private var inputViewHidden: Bool = false {
        didSet {
            self.inputBar?.isHidden = inputViewHidden
//            self.inputBarBottomPin?.isActive = !inputViewHidden
//            self.tableViewBottomConstraint?.isActive = inputViewHidden
        }
    }
    
    private var joinChatClosure: ChatInitClosure? = nil

    //MARK: - Outlets -
    @IBOutlet private weak var inputBar: ChatInputBar!
    @IBOutlet private weak var inputBarBottomPin: NSLayoutConstraint?
    @IBOutlet private weak var tableViewBottomConstraint: NSLayoutConstraint?
    @IBOutlet private weak var expertHeader: ExpertHeader!
    @IBOutlet private weak var tableView: UITableView!
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.messageService.add(delegate: self)
//        self.messageService.fetchMessages(self.pagination, opponent: self.opponentId, localStorageCompletion: { [weak self] messages in
//            
//            self?.messages = messages
//            self?.tableView.reloadData()
//            
//        }, remoteStorageCompletion: { [weak self] response in
//            self?.messages = response.messages
//            self?.pagination = response.pagination
//            
//            self?.tableView.reloadData()
//        }) { error in
//            if let error = error {
//                logger.log(error)
//            }
//        }

        self.chatPresenseService.setLoadingChat()
        self.setup(controller: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.keyboardCoordinator.subscribeForKeyboardEvents()
        
        if reachability.isNetworkReachable {
            self.connectToSokenAndReloadData()
        } else {
            SVProgressHUD.showError(withStatus: "The Internet connection appears to be offline.")
            SVProgressHUD.dismiss(withDelay: 2.0)
        }
//        
//        self.messageService.add(delegate: self)
//        self.fetchUser { [weak self] user in
//            guard let `self` = self else { return }
//
//            if user != nil {
//                if self.chatIsBlocked {
//                    //do nothing
//                } else {
//                    self.messageService.createDialog(receiver: self.opponentId) { error in
//                        if let error = error {
//                            print(error.localizedDescription)
//                        } else {
//                            print("joined to chat with \(self.opponentId ?? "")")
//                        }
//                    }
//                }
//            }
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.keyboardCoordinator.unsubscribeFromKeyboardEvents()
        
//        self.messageService.remove(delegate: self)
//        self.messageService.leaveDialog(receiver: self.opponentId) { error in
//            if let error = error {
//                print(error.localizedDescription)
//            } else {
//                print("leave to chat with \(self.opponentId ?? "")")
//            }
//        }
    }

    deinit {
        if let chatId = self.chatID, !chatId.isEmpty {
            self.socket.leave(chatID: chatId)
        }
        
        self.socket.remove(delegate: self)
    }

    //MARK: - Actions -
    @IBAction private func backButtonDidPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Private -
    private func reloadChat() {
        self.pagination = .default
        self.messages.removeAll()
        self.isLastMessageReaded = false
        
        self.tableView.reloadData()
        self.expertHeader.callButtonEnabled = !self.chatIsBlocked
    }
    
    private func fetchUser(completion: @escaping ObjectHandler<User?>) {
        self.api.fetchUser(id: self.opponentId) { result in
            switch result {
            case .success(let user):
                self.opponent = user
            case .failure(let error):
                logger.log(error)
            }
            
            completion(self.opponent)
        }
    }
    
    override func service(_ service: ReachabilityService, didChangeNetworkState state: Bool) {
        if state {
            self.connectToSokenAndReloadData()
        }
        
        self.inputBar.isEnabled = reachability.isNetworkReachable
    }
    
    private func connectToSokenAndReloadData() {
        
        self.expertHeader.isLoading = true
        self.expertHeader.callButtonEnabled = false
        
        self.fetchUser { [weak self] user in
            guard let `self` = self else { return }
            
            self.expertHeader.isLoading = false
            if let user = user {
                self.expertHeader.updateCallButton(enabled: !self.chatIsBlocked)
                self.expertHeader.setup(user: user)
            }
            
            self.setupChatSoket(user: user)
            self.reloadChat()
        }
    }
    
    private func setupChatSoket(user opponent: User?) {
        if let opponent = opponent {
            if self.chatIsBlocked {
                self.expertHeader.updateCallButton(enabled: false)
            } else {
                self.expertHeader.updateCallButton(enabled: opponent.isAvailable)
                self.createChat(with: opponent.id)
            }
        }
        
        self.updateUserInputBar(user: self.opponent, isBlocked: self.chatIsBlocked)
    }
    
    private func updateUserInputBar(user opponent: User?, isBlocked: Bool) {
        if let opponent = opponent {
            if isBlocked {
                if opponent.youWasBlocked {
                    self.inputViewHidden = !opponent.youWasBlocked
                    self.inputBar.isEnabled = false
                } else {
                    self.inputViewHidden = true
                }
            } else {
                self.inputViewHidden = false
                self.inputBar.isEnabled = true
            }
        }
    }
    
    private func setup(controller: ConversationViewController) {
        self.setup(view: self.view)
        self.setup(tableView: self.tableView)
        self.setup(keyboardCoordinator: self.keyboardCoordinator)
        
        self.inputBar.delegate = self
        self.expertHeader.delegate = self
        self.tableView.keyboardDismissMode = .onDrag
        
        self.socket.add(delegate: self)
        reachability.add(reachabylityDelegate: self)
        
        self.view.adjustConstraints()
        
        NotificationCenter.addDestroyCallWindowObserver { [weak self] in
            guard let `self` = self else { return }

            if reachability.isNetworkReachable {
                self.connectToSokenAndReloadData()
            }
        }
        
        NotificationCenter.addApplicationDidBecomeActiveObserver { [weak self] in
            guard let `self` = self else { return }
            
            if reachability.isNetworkReachable {
                self.connectToSokenAndReloadData()
                self.updateUserInputBar(user: self.opponent, isBlocked: self.chatIsBlocked)
            } else {
                self.inputBar.isEnabled = false
            }
        }
        
        NotificationCenter.addBlockUserObserver { [weak self] sender in
            guard let `self` = self else { return }
            
            if self.opponentId == sender {
                self.connectToSokenAndReloadData()
            }
        }
        
        NotificationCenter.addUnBlockUserObserver { [weak self] sender in
            guard let `self` = self else { return }
            
            if self.opponentId == sender {
                self.connectToSokenAndReloadData()
            }
        }
    }
    
    private func setup(view: UIView) {
        view.backgroundColor = textColor3
        self.inputBar.backgroundColor = textColor3
    }
    
    private func setup(keyboardCoordinator: KeyboardCoordinator) {
        self.keyboardCoordinator.update(with: self.view)
        self.keyboardCoordinator.willShowKeyboardHandler = { [weak self] value in
            self?.inputBarBottomPin?.constant = value
        }
        self.keyboardCoordinator.willHideKeyboardHandler = { [weak self] in
            self?.inputBarBottomPin?.constant = 0.0
        }
        
        self.keyboardCoordinator.updateLayoutHandler = { [weak self] in
            self?.updateEntireLayout()
        }
    }
    
    private func setup(tableView: UITableView) {
        tableView.registerNib(with: LoadingCell.self)
        tableView.registerNib(with: BlockedChatCell.self)
        tableView.registerNib(with: ChatReceiveMessageCell.self)
        tableView.registerNib(with: ChatSendMessageCell.self)
        tableView.registerNib(with: IncomingCallReceiveCell.self)
        tableView.registerNib(with: IncomingCallSendCell.self)
        tableView.registerNib(with: OutgoingCallReceiveCell.self)
        tableView.registerNib(with: OutgoingCallSendCell.self)
        tableView.registerNib(with: AcceptedCallReceiveCell.self)
        tableView.registerNib(with: AcceptedCallSendCell.self)
        tableView.registerNib(with: FinishedCallReceiveCell.self)
        tableView.registerNib(with: FinishedCallSendCell.self)
        tableView.registerNib(with: DeclinedCallReceiveCell.self)
        tableView.registerNib(with: DeclinedCallSendCell.self)
        tableView.registerNib(with: BackCallReceiveCell.self)
        tableView.registerNib(with: BackCallSendCell.self)
        tableView.registerNib(with: IncomingCallReceiveCell.self)
        tableView.registerNib(with: IncomingCallSendCell.self)
        
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
    }
    
    private func createChat(with oponent: String) {
        self.api.createChat(userID: nil, expertID: oponent) { [weak self] response in
            guard let `self` = self else { return }
            
            switch response {
            case .success(let chatId):
                self.joinToChat(with: chatId)
            case .failure(let error):
                logger.log(error)
                self.inputBar.isEnabled = false
            }
        }
    }
    
    private func joinToChat(with chatId: String) {
        self.chatID = chatId
        self.socket.join(chatID: chatId)
        self.updateUserInputBar(user: self.opponent, isBlocked: self.chatIsBlocked)
        
        self.view.layoutIfNeeded()
        self.tableView.reloadData()
    }
    
    private func playSendMessageSound() {
        guard let url = Bundle.main.url(forResource: "send_message", withExtension: "aif") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            self.player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = self.player else { return }
            
            player.play()
            
        } catch let error {
            logger.log(error)
        }
    }
    
    private func updateEntireLayout() {
        self.inputBar.updateLayout()

        UIView.animate(withDuration: 0.25, animations: {
            self.inputBar.textView.snapScrollPositionToInput = true
            self.view.layoutIfNeeded()
        }) { completed in
            self.inputBar.textView.snapScrollPositionToInput = false
        }
    }
    
    private func loadHistory(offset: Int, limit: Int) {
        guard let chatId = self.chatID, !self.isFetchingMessages else {
            return
        }
        
        self.isFetchingMessages = true
        self.api.getChatHistory(chatID: chatId, limit: limit, offset: offset) { result in
            self.isFetchingMessages = false
            
            switch result {
            case .success(let response):
                
                self.messages += response.rows
                self.pagination.totalCount = response.pagination.totalCount
                self.pagination.isEmpty = response.pagination.totalCount == 0
                
                self.tableView.reloadData()

                if self.isLastMessageReaded == false {
                    self.readCurrentMessages()
                    self.isLastMessageReaded = true
                }

            case .failure(let error):
                logger.log(error)
            }
        }
    }

    private func insertNewMessage(message: ChatMessage) {
        self.messages.insert(message, at: 0)

        let rowAnimation: UITableView.RowAnimation = .bottom
        let indexPaths = [IndexPath(row: 0, section: 0)]

        if self.messages.count > 1 {
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: indexPaths, with: rowAnimation)
            self.tableView.endUpdates()
            
            self.tableView.reloadRows(at: indexPaths, with: .automatic)
        } else {
            self.tableView.reloadData()
        }

        self.tableView.setContentOffset(.zero, animated: false)
    }
}

//MARK: - UITableViewDataSource
extension ConversationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let opponent = self.opponent {
            if self.chatIsBlocked {
                return opponent.youWasBlocked ? 0 : 1
            }
            
            var needLoading: Int = 1
            if self.messages.count > 0 && self.pagination.offset >= self.pagination.totalCount {
                needLoading = 0
            }
            
            if self.chatID == nil || self.chatID!.isEmpty || self.pagination.isEmpty {
                needLoading = 0
            }
            
            return self.messages.count + needLoading
        } else {
           return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.isScrollEnabled = !self.chatIsBlocked
        
        if self.chatIsBlocked && opponent!.youBlocked {
            let cell: BlockedChatCell = tableView.dequeueReusableCell(indexPath: indexPath)
            cell.delegate = self
            cell.transform = self.tableView.transform
            cell.unblockButtonEnabled = self.allowUnblock
            cell.blockedByMe = self.allowUnblock
            
            return cell
        }
        
        if indexPath.row == self.messages.count {
            let cell: LoadingCell = tableView.dequeueReusableCell(indexPath: indexPath)
            self.loadHistory(offset: self.pagination.offset, limit: self.pagination.limit)
            self.pagination.offset += self.pagination.limit
            
            return cell
        }
        
        let message = self.messages[indexPath.row]
        
        switch message.type {
        case .message:
            return self.cell(forMesage: message, at: indexPath)
        case .system(let type):
            return self.cell(forSystemMessage: message, at: indexPath, with: type)
        }
    }
    
    private func cell(forMesage message: ChatMessage, at indexPath: IndexPath) -> ChatTextCell {

        var cellToReuse: ChatTextCell
        if self.opponent!.id == message.senderId {
            let cell: ChatReceiveMessageCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
            cellToReuse = cell
        } else {
            let cell: ChatSendMessageCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
            cellToReuse = cell
        }
        
        cellToReuse.setup(with: message)
        cellToReuse.urlSelectedClosure = { [weak self] url in
            guard let `self` = self else { return }
            
            ModalStoryboard.showWEBView(with: url, from: self)
        }
        
        cellToReuse.transform = self.tableView.transform
        
        return cellToReuse
    }
    
    private func cell(forSystemMessage message: ChatMessage, at indexPath: IndexPath, with type: SystemMessageType) -> ChatSystemCell {
        var cellToReturn: ChatSystemCell
        let isIncomingMessage = self.opponent!.id == message.senderId
        
        switch type {
        case .incomingCall:
            if isIncomingMessage {
                let cell: IncomingCallReceiveCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            } else {
                let cell: IncomingCallSendCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            }
        case .outgoingCall:
            if isIncomingMessage {
                let cell: OutgoingCallReceiveCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            } else {
                let cell: OutgoingCallSendCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            }
        case .callWasAccepted:
            if isIncomingMessage {
                let cell: AcceptedCallReceiveCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            } else {
                let cell: AcceptedCallSendCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            }
        case .callWasFinished:
            if isIncomingMessage {
                let cell: FinishedCallReceiveCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            } else {
                let cell: FinishedCallSendCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            }
        case .callWasDeclined, .userDeclinedCall:
            if isIncomingMessage {
                let cell: DeclinedCallReceiveCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            } else {
                let cell: DeclinedCallSendCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            }
        case .callMeBack:
            if isIncomingMessage {
                let cell: BackCallReceiveCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            } else {
                let cell: BackCallSendCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            }
        default:
            if isIncomingMessage {
                let cell: IncomingCallReceiveCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            } else {
                let cell: IncomingCallSendCell = self.tableView.dequeueReusableCell(indexPath: indexPath)
                cellToReturn = cell
            }
        }
        
        cellToReturn.transform = self.tableView.transform
        cellToReturn.setup(with: message)
        
        return cellToReturn
    }
    
}

//MARK: - UITableViewDelegate
extension ConversationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let loadingCell = cell as? LoadingCell {
            loadingCell.spinner.startAnimating()
        }
    }
}

//MARK: - BlockedChatCellDelegate
extension ConversationViewController: BlockedChatCellDelegate {
    
    func unblockDidSelect() {
        guard let opponent = self.opponent else {
            return
        }
        
        SVProgressHUD.show()
        self.api.unblock(userID: opponent.id) { [weak self] error in
            SVProgressHUD.dismiss()
            
            guard let `self` = self else { return }
            
            if let error = error {
                logger.log(error)
            } else {
                self.opponent?.youBlocked = false
                self.opponent?.youWasBlocked = false
                
                self.createChat(with: opponent.id)
                self.expertHeader.updateCallButton(enabled: !self.chatIsBlocked)
            } 
        }
    }
}

//MARK: - ChatInputBarDelegate
extension ConversationViewController: ChatInputBarDelegate {
    
    func onTextChanged(with text: String) {
        let enteredText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let color = enteredText.isEmpty ? UIColor(red: 69, green: 79, blue: 99) : selectedColor
        self.inputBar.tintColor = color
    }
    
    func onSendButtonAction(text: String) {
        if text.isEmpty {
            return
        }
        
        guard let opponent = self.opponent else {
            return
        }
        
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sendMessageSafe(message: message, to: opponent.id)
        
//        self.messageService.send(message: message, to: opponent.id) { error in
//            if let error = error {
//                logger.log(error)
//            } else {
//
//            }
//        }
        
        self.inputBar.clear()
    }
    
    private func sendMessageSafe(message: String, to opponent: String) {
        if let userID = self.account.myUserID {
            if let chatId = self.chatID, !chatId.isEmpty {
                if self.socket.isJoinedToChat && self.socket.status == .connected {
                    self.socket.sendMessage(chatID: chatId, receiver: opponent, sender: userID, message: message)
                    self.playSendMessageSound()
                } else {
                    self.joinChatClosure = {
                        self.socket.sendMessage(chatID: chatId, receiver: opponent, sender: userID, message: message)
                        self.playSendMessageSound()
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
                        self.joinChatClosure = {
                            self.socket.sendMessage(chatID: chatId, receiver: opponent, sender: userID, message: message)
                            self.playSendMessageSound()
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
}

//MARK: - SocketWrapperDelegate
extension ConversationViewController: SocketWrapperDelegate {
    
    func soket(_ socket: SocketWrapper, didReceiveMessage message: ChatMessage) {
        if let chatId = self.chatID, !chatId.isEmpty {
            if !self.isFetchingMessages {
                self.insertNewMessage(message: message)
            }
            
            guard let opponent = self.opponent else {
                return
            }
            
            if let chatId = self.chatID, message.senderId == opponent.id {
                if let userID = self.account.myUserID {
                    self.socket.readMessage(chatID: chatId, myID: userID, lastMessageID: message.id)
                }
            }
        }
    }
    
    
    func soket(_ socket: SocketWrapper, didShangeStatus status: WrapperStatus) {
        
    }  

    func onDisconnect() {
        
    }

    func onConnect() {
        if let chatId = self.chatID, !chatId.isEmpty {
            self.socket.join(chatID: chatId)
        } 
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

//MARK: - UIScrollViewDelegate
extension ConversationViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let indicator = scrollView.subviews.last as? UIImageView else {
            return
        }
        
        indicator.backgroundColor = selectedColor
    }

    private func readCurrentMessages() {
        guard let indexes = self.tableView.indexPathsForVisibleRows else {
            return
        }
        
        guard let castedOpponent = self.opponent else {
            return
        }
        
        for index in stride(from: 0, through: indexes.count - 1, by: 1) {
            if index > self.messages.count {
                continue
            }
            
            let message = self.messages[index]
            if let chatId = self.chatID, message.senderId == castedOpponent.id {
                if let userID = self.account.myUserID {
                    self.socket.readMessage(chatID: chatId, myID: userID, lastMessageID: message.id)
                }
                
                break
            }
        }
    }
}

//MARK: - ExpertHeaderDelegate
extension ConversationViewController: ExpertHeaderDelegate {
    
    func callDidSelect(_ sender: UIButton) {
        sender.disable()
        
        if let opponent = self.opponent {
            self.callService.call(to: opponent) {
                sender.enable()
            }
        } 
    }
}

//MARK: - MessageServiceDelegate
extension ConversationViewController: MessageServiceDelegate {
    
    func service(_ service: MessageService, didUpdateDialog dialog: Conversation) {
        
    }
    
    func service(_ service: MessageService, didSendMessage message: ChatMessage) {
        if !self.isFetchingMessages {
            self.insertNewMessage(message: message)
        }
        
        self.playSendMessageSound()
    }
    
    func service(_ service: MessageService, didReceiveMessage message: ChatMessage) {
        if !self.isFetchingMessages {
            self.insertNewMessage(message: message)
        }
    }
}
