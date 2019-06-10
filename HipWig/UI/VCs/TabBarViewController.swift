//
//  TabBarViewController.swift
//  HipWig
//
//  Created by Alexey on 1/23/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Localize
import SVProgressHUD
import MulticastDelegateSwift

private enum TabItem: Int {
    case expertList
    case expertProfile
    case chatList
    case settings
    
    var title: String {
        switch self {
        case .chatList:
            return "tab_bar.chats".localized
        case .expertList:
            return "tab_bar.experts".localized
        case .expertProfile:
            return "tab_bar.profile".localized
        case .settings:
            return "tab_bar.settings".localized
        }
    }
}

class TabBarViewController: UITabBarController {

    //MARK: - Properties -
    private let iconOffset: CGFloat = -1.0
    private let iconTextOffset: CGFloat = -7.0
    private let account: AccountManager = .manager
    private let chatPresenseService: ChatPresenceService = ChatPresenceServiceImplementation.default
    private let callService: CallService = CallServiceImplementation.default
    private let api: RequestsManager = RequestsManager.manager
    private let shared: SharedStorage = SharedStorageImplementation.default
    private let pushHandler: PushHandler = PushHandler.handler
    private var conversation: Conversation?
    
    //MARK: - Interface -
    let tabBarViewControllerDelegate = MulticastDelegate<UITabBarControllerDelegate>()
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTabBarController()
        
        AppDelegate.shared.notificationsEnabled { [weak self] isEnabled, _ in
            guard let `self` = self else { return }
            
            if isEnabled {
                AppDelegate.shared.registerPushNotifications()
            }
            
            if let token = AppDelegate.shared.voipRegistry.pushToken(for: .voIP) {
                self.pushHandler.update(pushToken: token.tokenValue, type: .VOIP)
            }
        }

        self.setupTabBarAppearence()
        
        self.selectedIndex = 0
        self.setNeedsStatusBarAppearanceUpdate()
        self.delegate = self
        
        NotificationCenter.addApplicationDidBecomeActiveObserver { [weak self] in
            self?.checkUserRole { needRelogin in
                if needRelogin {
                    self?.doLogoutAfterChangeUserRole()
                } else {
                    if UIApplication.shared.eventState == .active {
                        NotificationCenter.postCheckIncomingCallEvent()
                    } else {
                        print(#function + "application isn't in active state")
                    }
                }
            }
        }
        
        NotificationCenter.addRoleChangeObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.doLogoutAfterChangeUserRole()
            self.callService.dissmissCallView()
        }
        
        NotificationCenter.addUpdateLocalizationObserver { [weak self] in
            self?.updateTextLabels()
        }
        
        NotificationCenter.addRecieveNewMessageObserver { [weak self] conversation, state in
            guard let `self` = self else { return }
            
            if state == .none {
                self.showConversation(conversation)
            } else {
                if self.chatPresenseService.loadingChat {
                    return
                }
                
                if conversation.id != self.chatPresenseService.selectedChatId {
                    if state == .background {
                        self.conversation = conversation
                    } else {
                        ModalStoryboard.showMessageNotification(with: conversation) { [weak self] in
                            guard let `self` = self else { return }
                            
                            self.showConversation(conversation)
                        }
                    }
                }
            }
        }
        
        NotificationCenter.addApplicationDidBecomeActiveObserver { [weak self] in
            guard let `self` = self else { return }
            
            if let conversation = self.conversation {
                self.conversation = nil
                self.showConversation(conversation)
            }
        }
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    private func showConversation(_ conversation: Conversation) {
        guard let source = self.selectedViewController as? UINavigationController else {
            return
        }
        
        if !self.callService.isCallingState {
            analytics.log(.open(screen: .conversation(user: conversation.opponent.name)))
            MainStoryboard.showConversation(from: source, with: conversation.opponent)
        }
    }
    
    private func checkForChatExisting(id: String, completion: @escaping (Bool) -> Void) {
        let pagination = Pagination.default(with: Int.max)
        self.api.getUserChats(pagination: pagination) { result in
            
            switch result {
            case .success(let response):
                let conversations = response.rows.filter{ $0.lastMessage != nil }
                
                let result = conversations.contains(where: { $0.id == id })
                completion(result)
            case .failure(let error):
                logger.log(error)
                completion(false)
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UIApplication.shared.eventState == .active {
            NotificationCenter.postMainScreenDidLoadedEvent()
        } else {
            print("application isn't in active state")
        }
    }
    
    //MARK: - Private -
    public func doLogoutAfterChangeUserRole() {
        self.account.logout { error in
            if let error = error {
                logger.log(error)
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                MainStoryboard.showLogin()
                ModalStoryboard.showRoleChange()
            }
        }
    }
    
    private func setupTabBarController() {
        var viewControllers: [UIViewController] = []
        
        if account.role == .expert {
            viewControllers.append(self.expertProfileViewController())
        } else {
            viewControllers.append(self.expertListViewController())
        }
        
        viewControllers.append(self.chatListViewController())
        if account.role == .expert {
            viewControllers.append(self.expertSettingsViewController())
        } else {
            viewControllers.append(self.userSettingsViewController())
        }
        
        self.setViewControllers(viewControllers, animated: false)
    }
    
    private func updateTextLabels() {
        self.tabBar.items?.forEach { item in
            if let itemValue = TabItem(rawValue: item.tag) {
                item.title = itemValue.title
            }
        }
    }

    private func expertListViewController() -> UIViewController {
        let vc: ExpertsListViewController = MainStoryboard.instantiate()
        assignTabBarItem(to: vc, image: "tab_expert_icon", item: .expertList)
        
        vc.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 25, vertical: self.iconTextOffset)
        vc.tabBarItem.imageInsets = UIEdgeInsets(top: self.iconOffset, left: 0.0, bottom: -self.iconOffset, right: 0.0)
        
        let nvc = HWNavigationController(rootViewController: vc)
        nvc.setNavigationBarHidden(true, animated: false)
        
        return nvc
    }
    
    private func expertProfileViewController() -> UIViewController {
        let vc: ExpertProfileViewController = MainStoryboard.instantiate()
        self.assignTabBarItem(to: vc, image: "tab_expert_icon", item: .expertProfile)
        
        vc.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 25, vertical: self.iconTextOffset)
        vc.tabBarItem.imageInsets = UIEdgeInsets(top: self.iconOffset, left: 0.0, bottom: -self.iconOffset, right: 0.0)
        
        let nvc = HWNavigationController(rootViewController: vc)
        nvc.setNavigationBarHidden(true, animated: false)
        
        return nvc
    }
    
    private func chatListViewController() -> UIViewController {
        let vc: ChatsListViewController = MainStoryboard.instantiate()
        self.assignTabBarItem(to: vc, image: "tab_chat_icon", item: .chatList)

        vc.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0.0, vertical: self.iconTextOffset)
        vc.tabBarItem.imageInsets = UIEdgeInsets(top: self.iconOffset, left: 0.0, bottom: -self.iconOffset, right: 0.0)
        
        let nvc = HWNavigationController(rootViewController: vc)
        nvc.setNavigationBarHidden(true, animated: false)
        
        return nvc
    }
    
    private func userSettingsViewController() -> UIViewController {
        let vc: UserSettingsViewController = MainStoryboard.instantiate()
        self.assignTabBarItem(to: vc, image: "tab_settings_icon", item: .settings)
        
        vc.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: -25, vertical: self.iconTextOffset)
        vc.tabBarItem.imageInsets = UIEdgeInsets(top: self.iconOffset, left: 0.0, bottom: -self.iconOffset, right: 0.0)

        let nvc = HWNavigationController(rootViewController: vc)
        nvc.setNavigationBarHidden(true, animated: false)
        
        return nvc
    }
    
    private func expertSettingsViewController() -> UIViewController {
        let vc: ExpertSettingsViewController = MainStoryboard.instantiate()
        self.assignTabBarItem(to: vc, image: "tab_settings_icon", item: .settings)
        
        vc.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: -25, vertical: self.iconTextOffset)
        vc.tabBarItem.imageInsets = UIEdgeInsets(top: self.iconOffset, left: 0.0, bottom: -self.iconOffset, right: 0.0)
        
        let nvc = HWNavigationController(rootViewController: vc)
        nvc.setNavigationBarHidden(true, animated: false)
        
        return nvc
    }
    
    private func assignTabBarItem(to viewController: UIViewController, image: String, item: TabItem) {
        viewController.tabBarItem = UITabBarItem(title: item.title, image: UIImage(named: image), tag: item.rawValue)
    }

    private func setupTabBarAppearence() {
        let attributes = [NSAttributedString.Key.font : Font.regular.of(size: 12)]
        self.tabBarItem.setTitleTextAttributes(attributes, for: .normal)
        self.tabBar.tintColor = selectedColor
        self.tabBar.barTintColor = UIColor(red: 35, green: 37, blue: 48)
        self.tabBar.shadowImage = UIImage()
    }

    private func checkUserRole(_ completion: @escaping (Bool) -> Void) {
        let lastRole = self.account.role
        if lastRole == .unknown {
            completion(false)
        }
        
        self.account.updateUser { [weak self] in
            guard let `self` = self else { return }
            
            completion(self.account.role != lastRole)
        }
    } 
}

//MAARK: - UITabBarControllerDelegate
extension TabBarViewController : UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        var shouldSelect: Bool = true
        self.tabBarViewControllerDelegate |> { delegate in
            shouldSelect = delegate.tabBarController?(tabBarController, shouldSelect: viewController) ?? true
        }
        
        return shouldSelect
    }
}
