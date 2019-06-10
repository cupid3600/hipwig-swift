//
//  AnalyticsManager.swift
//  HipWig
//
//  Created by Alexey on 2/8/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit 

enum LoginPushNotificationType: String {
    case facebook
    case google
    case instagram
}

enum Screen {
    case expertList
    case chatList
    case expert(name: String)
    case conversation(user: String)
    case call(to: String)
    case settions
    case profile
    case becomeExpert
    
    var name: String? {
        switch self {
            case .expertList: return "expert_list"
            case .chatList: return "chat_list"
            case .expert: return "expert_details"
            case .conversation: return "conversation"
            case .call: return "call"
            case .settions: return "settions"
            case .becomeExpert: return "become_an_expert"
            case .profile: return "profile"
        }
    }
    
    var params: [String: Any]? {
        switch self {
        case .expert(let receiver):
            return ["expert": receiver]
        case .call(let to):
            return ["with": to]
        case .conversation(let user):
            return ["with": user]
        default:
            return nil
        }
    }
}

enum AppEvent {
    case receivePushToken(token: Data)
    case login(type: LoginPushNotificationType)
    case logout
    case open(screen: Screen)
    case recordVideo
    case block(user: String)
    case unblock(user: String)
    case publishProfile
    case sound(muted: Bool)
    case select(filter: ExpertsFilter)
    case purchase(product: String, productType: String, amount: Double)
    case cancelPurchase(product: String)
}

extension AppEvent: AnalyticEvent {
    
    var name: String? {
        switch self {
        case .receivePushToken:
            return "push_token"
        case .login(let type):
            return "user_login_" + type.rawValue
        case .open(let screen):
            return "open_screen_\(screen.name ?? "Unknown")"
        case .recordVideo:
            return "user_recorded_video"
        case .block:
            return "block_user"
        case .unblock:
            return "unblock_user"
        case .publishProfile:
            return "publish_profile"
        case .sound:
            return "change_profile_video_sound_state"
        case .select(let filter):
            if filter.hasFilterValue {
                return "enable_experts_filter"
            } else {
                return "disable_experts_filter"
            }
        case .logout:
            return "logout"
        case .purchase:
            return "purchase"
        case .cancelPurchase:
            return "cancel_purchase"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .open(let screen):
            return screen.params
        case .block(let user), .unblock(let user):
            return ["user": user]
        case .sound(let muted):
            return ["is_muted": muted]
        case .select(let filter):
            var filterValue: [String: Any] = [:]
            
            if let location = filter.location {
                filterValue["location"] = location.value
            }
            if let purpose = filter.purpose {
                filterValue["purpose"] = purpose.value
            }
            if let sex = filter.sex {
                filterValue["sex"] = sex.value
            }
            
            return filterValue.isEmpty ? nil : filterValue
        default:
            return nil
        }
    }
}




