//
//  IAPService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/5/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String

protocol IAPPService: class {
    var canMakePayments: Bool { get }
    
    func fetchIAPProductList(for itemIds: Set<String>, originalOrder: [String], completion: @escaping FetchProductCompletion)
    func buy(with index: Int) -> Bool
    func restorePurchases()
    
    func prepareToUse()
}

class IAPPServiceImplementation: NSObject, IAPPService {
    
    static var `default`: IAPPServiceImplementation = IAPPServiceImplementation()
    
    private var fetchRequest: FetchProductsAction?
    private var skProducts: [SKProduct] = []
    private let paymantQueue = SKPaymentQueue.default()
    private let notificationCenter = NotificationCenter.default

    private override init() {
        super.init() 
    }
    
    func prepareToUse() {
        paymantQueue.add(self)
    }
    
    deinit {
        paymantQueue.remove(self)
    }
    
    func fetchIAPProductList(for itemIds: Set<String>, originalOrder: [String], completion: @escaping FetchProductCompletion) {
        self.fetchRequest = FetchProductsAction(itemIds) { [weak self] products in
            guard let `self` = self else { return }
            
            var orderedProucts: [SKProduct] = []
            for id in originalOrder {
                if let sortedElement = products.first(where: { $0.productIdentifier == id }) {
                    orderedProucts.append(sortedElement)
                }
            }
            
            self.skProducts = orderedProucts

            completion(self.skProducts.isEmpty)
        }
        
        self.fetchRequest?.perform()
    }
    
    func buy(with index: Int) -> Bool {
        if index >= 0 && index < self.skProducts.count {
            let product = self.skProducts[index]
            let payment = SKPayment(product: product)
            
            self.paymantQueue.add(payment)
            return true
        } else {
            return false
        } 
    }
    
    var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func restorePurchases() {
        self.paymantQueue.restoreCompletedTransactions()
    }
}

extension IAPPServiceImplementation: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                self.complete(transaction)
            case .failed:
                self.fail(transaction)
            case .restored:
                self.restore(transaction)
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    
    private func complete(_ transaction: SKPaymentTransaction) {
        print("complete...")
        
        let productIdentifier = transaction.payment.productIdentifier
        self.notificationCenter.post(name: .productPurchased, object: productIdentifier)
        
        self.paymantQueue.finishTransaction(transaction)
    }
    
    private func restore(_ transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("restore... \(productIdentifier)")
        
        self.paymantQueue.finishTransaction(transaction)
        
        self.notificationCenter.post(name: .productPurchased, object: productIdentifier)
    }
    
    private func fail(_ transaction: SKPaymentTransaction) {
        print("fail...")
        
        let productIdentifier = transaction.payment.productIdentifier
        if let transactionError = transaction.error as NSError? {
            
            if transactionError.code != SKError.paymentCancelled.rawValue {
                print("Transaction Error: \(transaction.error?.localizedDescription ?? "")")
                
                let transactionError = PurchaseTransactionError(error: transaction.error, productIdentifier: productIdentifier)
                self.notificationCenter.post(name: .productPurchaseFailed, object: transactionError)
            } else {
                self.notificationCenter.post(name: .productPurchaseCanceled, object: productIdentifier)
            }
            
        } else {
            self.notificationCenter.post(name: .productPurchaseFailed, object: productIdentifier)
        }
        
        self.paymantQueue.finishTransaction(transaction)
    }
}

typealias FetchProductCompletion = (_ isEmpty: Bool) -> Void

private class FetchProductsAction: NSObject, SKProductsRequestDelegate {
    
    private let completion: ([SKProduct]) -> Void
    
    private var productsRequest: SKProductsRequest?
    private let productIdentifiers: Set<ProductIdentifier>
    
    init(_ productIdentifiers: Set<ProductIdentifier>, completion: @escaping ([SKProduct]) -> Void) {
        self.completion = completion
        self.productIdentifiers = productIdentifiers
    }
    
    func perform() {
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        completion(response.products)
    }
}

extension Notification.Name {
    static let productPurchased = Notification.Name(rawValue: "productPurchasedNotificationKey")
    static let productPurchaseCanceled = Notification.Name(rawValue: "productPurchaseCanceledNotificationKey")
    static let productPurchaseFailed = Notification.Name(rawValue: "productPurchaseFailedNotificationKey")
}

struct PurchaseTransactionError {
    let error: Error?
    let productIdentifier: ProductIdentifier
}

//struct DelegatedCall<Input> {
//
//    private(set) var callback: ((Input) -> Void)?
//
//    mutating func delegate<Object : AnyObject>(to object: Object, with callback: @escaping (Object, Input) -> Void) {
//        self.callback = { [weak object] input in
//            guard let object = object else {
//                return
//            }
//            callback(object, input)
//        }
//    }
//}

//class ImageDownloader {
//
//    var didDownload = DelegatedCall<UIImage>()
//
//    func downloadImage(for url: URL) {
//        download(url: url) { image in
//            self.didDownload.callback?(image)
//        }
//    }
//}
//class Controller {
//
//    let downloader = ImageDownloader()
//    var image: UIImage?
//
//    init() {
//        downloader.didDownload.delegate(to: self) { (self, image) in
//            self.image = image
//        }
//    }
//
//    func updateImage() {
//        downloader.downloadImage(for: /* some image url */)
//    }
//}

extension NotificationCenter {
    
//    class func addProductPurchasedObserver<T: Some>(_ target: T, _ completion: @escaping (ProductIdentifier) -> Void) {
//        
////        NotificationCenter.default.addObserver(target, selector: #selector(didReceiveNotification(_:)), name: .productPurchased, object: nil)
//        
//        NotificationCenter.default.addObserver(forName: .productPurchased, object: nil, queue: .main) { notification in
//            guard let productId = notification.object as? String else { return }
//            completion(productId)
//        }
//    }
    
    class func addProductPurchasedObserver(_ completion: @escaping (ProductIdentifier) -> Void) {
        NotificationCenter.default.addObserver(forName: .productPurchased, object: nil, queue: .main) { notification in
            guard let productId = notification.object as? String else { return }
            completion(productId)
        }
    }
    
    class func addProductPurchaseCanceledObserver(_ completion: @escaping (ProductIdentifier) -> Void) {
        NotificationCenter.default.addObserver(forName: .productPurchaseCanceled, object: nil, queue: .main) { notification in
            guard let productId = notification.object as? String else { return }
            completion(productId)
        }
    }
    
    class func addProductPurchaseFailedObserver(_ completion: @escaping (PurchaseTransactionError) -> Void) {
        NotificationCenter.default.addObserver(forName: .productPurchaseFailed, object: nil, queue: .main) { notification in
            guard let error = notification.object as? PurchaseTransactionError else { return }
            
            completion(error)
        }
    }
}
