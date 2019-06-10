//
//  SubscriptionPlan.swift
//  HipWig
//
//  Created by Alexey on 1/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation

protocol ProductService: class {
    
    var shouldUploadRecipe: Bool { get }
    var selectedProduct: Product? { get }
    var productCount: Int { get }
    var products: [Product] { get }
    var discountTimedOut: Bool { get }
    var leftDiscountTime: TimeInterval { get set }
    var showDiscountFirstTime: Bool { get }
    
    subscript(_ index: Int) -> Product { get }
    
    func selectProduct(index: Int)
    func buy(product: Product, completion: @escaping (ProductServiceError?) -> Void)
    func fetchProductList(ofType: ProductType, completion: @escaping (_ isEmpty: Bool) -> Void)
    func restoreDiscountTime()
    static var hasUploadRecipeTaskForCurrentUser: Bool { get }
    
    static func updateUploadRecipeStatus(needUpload value: Bool)
    static func removeUploadRecipeTaskForCurrentUser()
}

enum ProductServiceError: Error {
    
    case PurchaseUnavailable
    case EmptyProductList
    case AppStoreReceiptNotFound
    case Internal(Error)
    
    var localizedDescription: String {
        switch self {
        case .PurchaseUnavailable:
            return "Operation canceled. Purchase unavailable"
        case .AppStoreReceiptNotFound:
            return "Operation canceled. AppStore receipt not found"
        case .EmptyProductList:
            return "Operation canceled. Empty product list"
        case .Internal(let error):
            return error.localizedDescription
        }
        
    }
}

private let uploadRecipePrefix = "UploadRecipe_"
private var uploadRecipeKeyForCurrentUser: String? {
    if let userId = AccountManager.manager.myUserID {
        return uploadRecipePrefix + userId
    } else {
        return nil
    }
}

private let leftDiscountTimeKey = "leftDiscountTimeKey"
private let discountShownKey = "discountShownKey"
private extension UserDefaults {
    
    class var leftDiscountTime: TimeInterval? {
        get {
            return UserDefaults.standard.value(forKey: leftDiscountTimeKey) as? TimeInterval
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: leftDiscountTimeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: leftDiscountTimeKey)
            }
            
            UserDefaults.standard.synchronize()
        }
    }
    
    class var showDiscountFirstTime: Bool {
        return UserDefaults.standard.value(forKey: discountShownKey) == nil
    }
    
    class func showDiscountPupupShown() {
        UserDefaults.standard.set(true, forKey: discountShownKey)
        UserDefaults.standard.synchronize()
    }
}

class ProductServiceImplementation: NSObject, ProductService {

    private var storeService: IAPPService = IAPPServiceImplementation.default
    private let api: RequestsManager = RequestsManager.manager
    private static let keychain = KeychainSwift(keyPrefix: "HipWig_")
    private let purchaseObserverTokenKey = "PurchaseObserverTokenKey"
    private (set) var products: [Product] = []
    private (set) var selectedProduct: Product?
    private var index: Int?
    private var productToBye: Product?
    private var buyProductCompletion: ((ProductServiceError?) -> Void)?
    
    static let `default`: ProductServiceImplementation = ProductServiceImplementation()
    
    static func updateUploadRecipeStatus(needUpload value: Bool) {
        if let key = uploadRecipeKeyForCurrentUser {
            ProductServiceImplementation.keychain.set(value, forKey: key)
        }
    }
    
    static var hasUploadRecipeTaskForCurrentUser: Bool {
        if let key = uploadRecipeKeyForCurrentUser {
            return ProductServiceImplementation.keychain.getBool(key) != nil
        } else {
            return false
        }
    }
    
    static func removeUploadRecipeTaskForCurrentUser() {
        if let key = uploadRecipeKeyForCurrentUser {
            ProductServiceImplementation.keychain.delete(key)
        }
    }
    
    var discountTimedOut: Bool {
        if let time = UserDefaults.leftDiscountTime {
            return time > 0
        } else {
            return false
        } 
    }
    
    var leftDiscountTime: TimeInterval {
        get {
            if let time = UserDefaults.leftDiscountTime {
                return time
            } else {
                return 0.0
            }
        } set {
            UserDefaults.leftDiscountTime = newValue
        }
    }
    
    var showDiscountFirstTime: Bool {
        get {
            let value = UserDefaults.showDiscountFirstTime
            
            if value {
                
                UserDefaults.showDiscountPupupShown()
                UserDefaults.leftDiscountTime = 86400.0 //24 hours
            }
            
            return value
        }
    }
    
    func restoreDiscountTime() {
        
    }
    
    private override init() {
        super.init()
        
        NotificationCenter.addProductPurchasedObserver { [weak self] productIdentifier in
            guard let `self` = self else {
                return
            }
            
            if let product = self.productToBye,
               let completion = self.buyProductCompletion {
                
                if productIdentifier == product.id {
                    if let recipe = UIApplication.shared.recipe {
                        ProductServiceImplementation.updateUploadRecipeStatus(needUpload: true)
                        
                        self.api.uploadReceipt(recipe: recipe) { error in
                            var resultError: ProductServiceError?
                            if let error = error {
                                ProductServiceImplementation.updateUploadRecipeStatus(needUpload: true)
                                resultError = .Internal(error)
                            } else {
                                analytics.log(.purchase(product: product.id, productType: product.type.rawValue, amount: product.priceValue))
                                
                                ProductServiceImplementation.removeUploadRecipeTaskForCurrentUser()
                            }
                            
                            completion(resultError)
                            
                            self.resetAfterPaymant()
                        }
                    } else {
                        completion(.AppStoreReceiptNotFound)
                        
                        self.resetAfterPaymant()
                    }
                }
            }
        }
    }
    
    func fetchProductList(ofType type: ProductType, completion: @escaping (_ isEmpty: Bool) -> Void) {
        self.api.fetchProductInfoList { result in
            switch result {
            case .success(let productList):
                self.products = productList.filter{ $0.type == type && !$0.title.isEmpty }
                self.selectedProduct = self.products.first

                let orderedIds = self.products.map{ $0.id }
                let productIds = Set(orderedIds)
                
                if productIds.isEmpty {
                    completion(true)
                } else {
                    self.storeService.fetchIAPProductList(for: productIds, originalOrder: orderedIds) { isEmpty in
                        completion(isEmpty)
                    }
                }
            case .failure(let error):
                logger.log(error)
                completion(true)
            }
        }
    }
    
    var shouldUploadRecipe: Bool {
        if let uploadKey = uploadRecipeKeyForCurrentUser {
            if let value = ProductServiceImplementation.keychain.getBool(uploadKey) {
                return value
            }
        }
        
        return false
    }

    func selectProduct(index: Int) {
        guard !self.products.isEmpty else {
            return
        }
        
        self.selectedProduct = self.products[index]
    }
    
    subscript(_ index: Int) -> Product {
        get {
            return self.products[index]
        }
    }
    
    var productCount: Int {
        return self.products.count
    }
    
    func buy(product: Product, completion: @escaping (ProductServiceError?) -> Void) {
        if self.storeService.canMakePayments {
            if let index = self.products.lastIndex(where: { $0.id == product.id }) {
                self.productToBye = product
                self.buyProductCompletion = completion
                
                if !self.storeService.buy(with: index) {
                    completion(.EmptyProductList)
                    
                    self.resetAfterPaymant()
                }
            } else {
                completion(.EmptyProductList)
                
                self.resetAfterPaymant()
            }
        } else {
            completion(.PurchaseUnavailable)
            
            self.resetAfterPaymant()
        }
    }
    
    private func resetAfterPaymant() {
        self.buyProductCompletion = nil
        self.productToBye = nil
    }
}
