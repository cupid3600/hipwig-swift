//
//  ChatListViewController.swift
//  HipWig
//
//  Created by Alexey on 1/23/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import MGSwipeTableCell
import SVProgressHUD 

class ChatsListViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var separatorView: UIView!
    @IBOutlet private var refreshTableActivityIndicator: UIActivityIndicatorView!

    //MARK: - Properties -
    private var conversations: [Conversation] = []
    private var pagination: Pagination = .default
    private var featureFlags = ChatListFeatureFlagCategoryimplementation.default
    private let refreshControl = UIRefreshControl()
    private let chatPresenseService: ChatPresenceService = ChatPresenceServiceImplementation.default
    private let account: AccountManager = AccountManager.manager
    private let socket = SocketWrapper.wrapper
    private let api: RequestsManager = RequestsManager.manager
    private let messageService: MessageService = MessageServiceImplementation.default
    
    private var showRefreshAnimation: Bool = false {
        didSet {
            if showRefreshAnimation {
                self.refreshTableActivityIndicator.startAnimating()
            } else {
                self.refreshTableActivityIndicator.stopAnimating()
            }
        }
    }
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.conversations.isEmpty {
            self.showRefreshAnimation = true
        }
        
        self.refreshChatList()
        analytics.log(.open(screen: .chatList))
//        self.messageService.add(delegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        self.messageService.remove(delegate: self)
    }
    
    deinit {
        print(#file + " " + #function)
    }

    //MARK: - Private -
    private func onLoad() {
        
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = self.refreshControl
        } else {
            self.tableView.addSubview(self.refreshControl)
        }
        
        self.tableView.addInfiniteScroll { [weak self] tableView in
            guard let `self` = self else { return }
            
            self.fetchMoreChats { result in
                switch result {
                case .success(let indexPaths):
                    if let indexPathsToInsert = indexPaths {
                        tableView.performBatchUpdates({
                            tableView.insertRows(at: indexPathsToInsert, with: .none)
                        })
                    }
                case .failure(let error):
                    logger.log(error)
                }

                tableView.finishInfiniteScroll()
            }
        }
        
        self.tableView.setShouldShowInfiniteScrollHandler { [weak self] _ in
            guard let `self` = self else { return false }
            
            return self.pagination.hasNextPage
        }
        
        self.setup(refreshControl: self.refreshControl)
        self.tableView.registerNib(with: ChatListCell.self)
        self.tableView.tableFooterView = UIView() 
        self.separatorView.backgroundColor = kBackgroundColor
        NotificationCenter.addRecieveNewMessageObserver { [weak self] conversation, state in
            guard let `self` = self else { return }
            
            if state == .active {
                self.reloadConversationList(with: conversation)
            }
        }
        
        NotificationCenter.addBlockUserObserver { [weak self] _ in
            guard let `self` = self else { return }
            
            self.refreshChatList()
        }
        
        NotificationCenter.addUnBlockUserObserver { [weak self] _ in
            guard let `self` = self else { return }
            
            self.refreshChatList()
        }
        
        self.view.adjustConstraints()
    }
    
    override func service(_ service: ReachabilityService, didChangeNetworkState state: Bool) {
        if state {
            self.refreshChatList()
        }
    }
    
    private func setup(refreshControl: UIRefreshControl) {
        refreshControl.addTarget(self, action: #selector(refreshChatList), for: .valueChanged)
        refreshControl.tintColor = textColor2
    }
    
    @objc private func refreshChatList() {
        self.fetchChatList { [weak self] error in
            guard let `self` = self else { return }
            
            if let error = error {
                logger.log(error)
            }
            
            self.tableView.reloadData()
            
            self.showRefreshAnimation = false
            self.refreshControl.endRefreshing()
            
            self.tableView.contentOffset = .zero
        }
    }
    
    func fetchChatList(completion: @escaping ErrorHandler) {
        self.pagination = .default
        
        self.pagination.isFetching = true
        self.api.getUserChats(pagination: self.pagination) { [weak self] result in
            guard let `self` = self else { return }

            switch result {
            case .success(let response):
                self.pagination = response.pagination
                self.conversations = response.rows.filter{ $0.lastMessage != nil }

                completion(nil)
            case .failure(let error):

                self.pagination.isFetching = false
                completion(error)
            }
        }
        
//        self.messageService.fetchDialogs(self.pagination) { [weak self] result in
//            guard let `self` = self else {
//                return
//            }
//
//            switch result {
//            case .failure(let error):
//                self.pagination.isFetching = false
//
//                completion(error)
//            case .success(let response):
//                self.pagination = response.pagination
//                self.conversations = response.dialogs.filter{ $0.lastMessage != nil }
//
//                completion(nil)
//            }
//        }
    }
    
    func fetchMoreChats(completion: @escaping ValueHandler<[IndexPath]?>) {
        if !self.pagination.hasNextPage || self.pagination.isFetching {
            return
        }
        
        self.pagination.isFetching = true
        self.pagination.calculateNextPage()
        
        self.api.getUserChats(pagination: self.pagination) { [weak self] result in
            guard let `self` = self else { return }

            switch result {
            case .success(let response):

                let prevCount = self.conversations.count

                let chatList = response.rows.filter{ $0.lastMessage != nil }
                self.conversations.append(contentsOf: chatList)

                let newCount = self.conversations.count

                var indexPaths: [IndexPath]? = nil
                if prevCount != newCount {
                    indexPaths = (prevCount ..< newCount).map { IndexPath(row: $0, section: 0) }
                }

                self.pagination = response.pagination
                self.pagination.isFetching = false

                completion(.success(indexPaths))
            case .failure(let error):
                self.pagination.isFetching = false

                completion(.failure(error))
            }
        }
        
//        self.messageService.fetchDialogs(self.pagination) { [weak self] result in
//            guard let `self` = self else {
//                return
//            }
//
//            switch result {
//            case .success(let response):
//                let prevCount = self.conversations.count
//
//                let dialogs = response.dialogs.filter{ $0.lastMessage != nil }
//                self.conversations.append(contentsOf: dialogs)
//
//                let newCount = self.conversations.count
//
//                var indexPaths: [IndexPath]? = nil
//                if prevCount != newCount {
//                    indexPaths = (prevCount ..< newCount).map { IndexPath(row: $0, section: 0) }
//                }
//
//                self.pagination = response.pagination
//                self.pagination.isFetching = false
//
//                completion(.success(indexPaths))
//
//            case .failure(let error):
//                self.pagination.isFetching = false
//
//                completion(.failure(error))
//            }
//        }
    }

    private func deleteConversation(_ id: String, indexPath: IndexPath) {
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        
        self.api.deleteChat(chatID: id) { [weak self] error in
            guard let `self` = self else { return }

            SVProgressHUD.dismiss()

            if let error = error {
                logger.log(error)
                ModalStoryboard.showDeleteChatError()
            } else {
                self.pagination.totalCount -= 1
                self.pagination.isEmpty = self.pagination.totalCount == 0

                self.conversations.remove(at: indexPath.row)

                self.tableView.deleteRows(at: [indexPath], with: .right)
                self.tableView.reloadData()
            }
        }
        
//        self.messageService.delete(dialog: id) { [weak self] error in
//            guard let `self` = self else { return }
//
//            SVProgressHUD.dismiss()
//
//            if let error = error {
//                logger.log(error)
//            } else {
//                self.pagination.totalCount -= 1
//                self.pagination.isEmpty = self.pagination.totalCount == 0
//
//                self.conversations.remove(at: indexPath.row)
//
//                self.tableView.deleteRows(at: [indexPath], with: .right)
//                self.tableView.reloadData()
//            }
//        }
    }

    private func blockConversation(userID: String, indexPath: IndexPath) {
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        
        self.api.block(userID: userID) { [weak self] error in
            guard let `self` = self else { return }
            
            SVProgressHUD.dismiss()
            
            if let error = error {
                logger.log(error)
                ModalStoryboard.showBlockChatError()
            } else {
                var chat = self.conversations[indexPath.row]
                
                chat.opponent.youBlocked = true
                self.conversations[indexPath.row] = chat
                
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.reloadData()
            }
        }
        
        analytics.log(.block(user: userID))
    }

    private func unblockConversation(userID: String, indexPath: IndexPath) {
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        
        self.api.unblock(userID: userID) { [weak self] error in
            guard let `self` = self else { return }
            
            SVProgressHUD.dismiss()
            
            if let error = error {
                logger.log(error)
                ModalStoryboard.showUnblockChatError()
            } else {
                var chat = self.conversations[indexPath.row]
                chat.opponent.youBlocked = false
                self.conversations[indexPath.row] = chat
                
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.reloadData()
            }
        }
        
        analytics.log(.unblock(user: userID))
    }
    
    private func reloadConversationList(with chatToUpdate: Conversation) {
        if chatToUpdate.id == self.chatPresenseService.selectedChatId {
            return
        }
        
        if let index = self.conversations.firstIndex(where: { $0.id == chatToUpdate.id }) {
            let oponent = self.conversations[index].opponent
            if !oponent.youBlocked && !oponent.youWasBlocked {
                self.conversations[index] = chatToUpdate
            }
        } else {
            self.conversations.append(chatToUpdate)
        }
        
        self.conversations = self.conversations.sorted { chat1, chat2 in
            guard let lastMsg1 = chat1.lastMessage, let lastMsg2 = chat2.lastMessage else {
                return false
            }
            
            return lastMsg1.createdAt.compare(lastMsg2.createdAt) == .orderedDescending
        }
        
        self.tableView.reloadData()
    }
}

//MARK: - UITableViewDelegate
extension ChatsListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88.0.adjusted
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if reachability.isNetworkReachable {
        
            let chat = self.conversations[indexPath.row]
            if let target = self.navigationController {
                
                analytics.log(.open(screen: .conversation(user: chat.opponent.name)))
                MainStoryboard.showConversation(from: target, with: chat.opponent)
            }
        }
    }
}

//MARK: - UITableViewDataSource
extension ChatsListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: ChatListCell = tableView.dequeueReusableCell(indexPath: indexPath)
        cell.hideSwipe(animated: true)

        let chat = self.conversations[indexPath.row]
        cell.setup(chat: chat)

        let leftButtons = self.deleteChatButton(cell: cell, chat: chat, indexPath: indexPath)
        cell.leftButtons = self.featureFlags.deleteChatEnabled ? leftButtons : []
        
        if chat.opponent.youBlocked || chat.opponent.youWasBlocked {
            if self.featureFlags.blockUserEnabled && !chat.opponent.youWasBlocked {
                cell.rightButtons = self.unblockUserButton(cell: cell, chat: chat, indexPath: indexPath)
            } else {
                cell.rightButtons = []
            }
        } else {
            if self.featureFlags.blockUserEnabled && !chat.opponent.youWasBlocked {
                cell.rightButtons = self.blockUserButton(cell: cell, chat: chat, indexPath: indexPath)
            } else {
                cell.rightButtons = []
            }
        }
        
        cell.leftSwipeSettings.transition = .border

        return cell
    }

    private func deleteChatButton(cell: ChatListCell, chat: Conversation, indexPath: IndexPath) -> [MGSwipeButton] {
        let bcgColor = UIColor(red: 255, green: 79, blue: 79)
        
        let button = MGSwipeButton(title: "chat.delete_chat".localized, backgroundColor: bcgColor) { [weak self] cell in
            guard let `self` = self else { return false }
            
            self.deleteConversation(chat.id, indexPath: indexPath)
            
            return true
        }

        button.setImage(UIImage(named: "chat_delete_icon"), for: .normal)
        button.setTitleColor(kPeranoColor, for: .normal)
        button.titleLabel?.font = button.titleLabel?.font.adjusted
        button.buttonWidth = 110.0.adjusted
        button.centerVertically(padding: 5.0)
        
        return [button]
    }
    
    private func unblockUserButton(cell: ChatListCell, chat: Conversation, indexPath: IndexPath) -> [MGSwipeButton] {
        let bcgColor = UIColor(red: 255, green: 79, blue: 154)
        
        let button = MGSwipeButton(title: "chat.unblock_chat".localized, backgroundColor: bcgColor) { [weak self] cell in
            guard let `self` = self else { return false }
            
            self.unblockConversation(userID: chat.opponent.id, indexPath: indexPath)
            
            return true
        }
        
        button.setImage(UIImage(named: "chat_blocked_icon"), for: .normal)
        button.setTitleColor(kPeranoColor, for: .normal)
        button.titleLabel?.font = button.titleLabel?.font.adjusted
        button.buttonWidth = 110.0.adjusted
        button.centerVertically(padding: 5.0)
        button.isEnabled = chat.opponent.youBlocked
        
        return [button]
    }
    
    private func blockUserButton(cell: ChatListCell, chat: Conversation, indexPath: IndexPath) -> [MGSwipeButton] {
        let bcgColor = UIColor(red: 255, green: 79, blue: 154)
        
        let button = MGSwipeButton(title: "chat.blocked_chat".localized, backgroundColor: bcgColor) { [weak self] cell in
            guard let `self` = self else { return false }
            
            self.blockConversation(userID: chat.opponent.id, indexPath: indexPath)
            
            return true
        }
        
        button.setImage(UIImage(named: "chat_blocked_icon"), for: .normal)
        button.setTitleColor(kPeranoColor, for: .normal)
        button.titleLabel?.font = button.titleLabel?.font.adjusted
        button.buttonWidth = 110.0.adjusted
        button.centerVertically(padding: 5.0)
        
        return [button]
    }
}

//MARK: - MessageServiceDelegate -
extension ChatsListViewController: MessageServiceDelegate {
    
    func service(_ service: MessageService, didUpdateDialog dialog: Conversation) {
        if let index = self.conversations.firstIndex(where: { $0.id == dialog.id }) {
            self.conversations[index] = dialog
            
            self.tableView.reloadData()
        }
    }
    
    func service(_ service: MessageService, didSendMessage message: ChatMessage) {
        //Do nothing
    }
    
    func service(_ service: MessageService, didReceiveMessage message: ChatMessage) {
        //Do nothing
    } 
}
