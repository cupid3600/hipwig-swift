//
//  Product.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/22/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

enum ProductType: String, Codable {
    case subscription
    case product
}

enum SubscriptionError: Error {
    case parse
}

struct Product: Codable {
    
    let id: String
    let title: String
    let price: String
    let discount: String
    let isBought: Bool
    let featureTitles: [String]
    let type: ProductType
    
    //FIXME:
    let description: String
    let payForText: String
    let centerText: String
    var priceValue: Double {
        var price = 0.0
        let priceValue = self.price.replacingOccurrences(of: "$", with: "")
        if let p = Double(priceValue) {
            price = p
        }
        
        return price
    }
    
    private enum SubscriptionCodingKeys: String, CodingKey {
        case id = "subscription_id"
        case title = "subscription_title"
        case price = "subscription_price"
        case discount = "subscription_discount"
        case centerText = "product_center_text"
    }
    
    private enum ProductCodingKeys: String, CodingKey {
        case id = "product_id"
        case title = "product_title"
        case price = "product_price"
        case discount = "product_discount"
        case centerText = "product_center_text"
    }
    
    init(from decoder: Decoder) throws {
        
        let container1 = try decoder.container(keyedBy: SubscriptionCodingKeys.self)
        let container2 = try decoder.container(keyedBy: ProductCodingKeys.self)

        let features = ["subscription.subscription_features.counselor".localized,
                        "subscription.subscription_features.messages".localized,
                        "subscription.subscription_features.video_call".localized,
                        "subscription.subscription_features.superstar_counselor".localized]

        if container1.contains(.id) {
            id = try container1.decode(String.self, forKey: .id)

            if container1.contains(.title) {
                title = try container1.decode(String.self, forKey: .title)
            } else {
                title = "some title"
            }

            if container1.contains(.price) {
                price = try container1.decode(String.self, forKey: .price)
            } else {
                price = "2.5$"
            }

            if container1.contains(.discount) {
                discount = try container1.decode(String.self, forKey: .discount)
            } else {
                discount = "0.5"
            }

            isBought = false
            featureTitles = features
            description = "Join thousands of happy users"
            type = .subscription
            payForText = ""
            centerText = "Most \npopular"
        } else if container2.contains(.id) {
            id = try container2.decode(String.self, forKey: .id)

            if container2.contains(.title) {
                title = try container2.decode(String.self, forKey: .title)
            } else {
                title = ""
            }

            if container2.contains(.price) {
                price = try container2.decode(String.self, forKey: .price)
            } else {
                price = "2.5$"
            }

            if container2.contains(.discount) {
                discount = try container2.decode(String.self, forKey: .discount)
            } else {
                discount = "0.5"
            }

            isBought = false
            featureTitles = features
            description = "subscription.subscription_common_texts.join".localized
            type = .product
            payForText = "some"
            
            if container1.contains(.centerText) {
                centerText = try container1.decode(String.self, forKey: .centerText)
            } else {
                centerText = "Most \npopular"
            }
            
        } else {
            throw SubscriptionError.parse
        }
        
    }
}
