//
//  SubscriptionPlansViewController.swift
//  HipWig
//
//  Created by Alexey on 1/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD

private enum Section: Int, CaseIterable {
    case price
    case details
    case bye
}

class SubscriptionPlansViewController: BaseViewController {

    public var backAction: ((_ target: BaseViewController, _ showDiscount: Bool) -> Void)?
    public var completionAction: ((_ target: BaseViewController) -> Void)?

    //MARK: - Outlets -
    @IBOutlet private var segmentControl: SegmenView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!

    //MARK: - Properties -
    private let productService: ProductService = ProductServiceImplementation.default
    private let account: AccountManager = AccountManager.manager
    private var isInPaymantProgress = false
    private var allowPurchase = true
    private weak var paymantCell: BuySubscriptionCell?
    private var api: RequestsManager = RequestsManager.manager
    
    //MARK: - LifeCycle -
    override func viewDidLoad() {
        super.viewDidLoad()
 
        self.segmentControl.titles = ["", "", ""]
        self.segmentControl.delegate = self
        self.segmentControl.isHidden = true

        self.tableView.registerNib(with: SubscriptionPriceCell.self)
        self.tableView.registerNib(with: BuySubscriptionCell.self)
        self.tableView.registerNib(with: SubscriptionInfoCell.self)
        
        NotificationCenter.addProductPurchaseFailedObserver { [weak self] result in
            guard let `self` = self else { return }
            
            self.activityIndicatorView.stopAnimating()
            SVProgressHUD.dismiss()
            
            if let error = result.error {
                logger.log(error)
            }
            
            self.isInPaymantProgress = false
        }
        
        NotificationCenter.addProductPurchaseCanceledObserver { [weak self] indentifier in
            guard let `self` = self else { return }
            
            self.activityIndicatorView.stopAnimating()
            SVProgressHUD.dismiss()
            
            self.isInPaymantProgress = false
            analytics.log(.cancelPurchase(product: indentifier))
        }
        
        self.view.adjustConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.activityIndicatorView.startAnimating()
        self.productService.fetchProductList(ofType: .subscription) { [weak self] isEmptyProductList in
            guard let `self` = self else { return }
            
            self.activityIndicatorView.stopAnimating()
            
            self.segmentControl.isHidden = false
            self.segmentControl.titles = self.productService.products.filter{ !$0.title.isEmpty }.map{ $0.title }
            
            self.tableView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if isEmptyProductList {
                    if reachability.isNetworkReachable {
                        ModalStoryboard.showUnavailablePurchase()
                    } else {
                        ModalStoryboard.showUnavailableNetwork()
                    }
                }
                
                self.paymantCell?.allowChoosingPlan = !isEmptyProductList
            }
            
            
//            if let plan = self.account.user?.subscribedTo {
//                //FIXME:
//            } else {
            if self.productService.selectedProduct != nil {
                self.segmentControl.selectSegment(0)
            }
//            }
        }
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Actions -
    override func backDidSelect(_ sender: UIButton) {
        self.backAction?(self, true)
    } 
}

//MARK: - ThreeSegmentControlDelegate
extension SubscriptionPlansViewController: SegmentViewDelegate {
    
    func segmentView(_ segmentView: SegmenView, shouldSelectSegmentWithIndex index: Int) -> Bool {
        return true
    }
    
    func segmentView(_ segmentView: SegmenView, didSelectSegmentWithIndex index: Int) {
        if self.isInPaymantProgress {
            return
        }
        
        self.productService.selectProduct(index: index)
        
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
        self.tableView.contentOffset = .zero
    }
}

//MARK: - UITableViewDelegate
extension SubscriptionPlansViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}

//MARK: - UITableViewDataSource
extension SubscriptionPlansViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.productService.selectedProduct == nil {
            return 0
        } else {
            return Section.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.price.rawValue || section == Section.bye.rawValue {
            return 1
        }
        
        guard let subscription = self.productService.selectedProduct else {
            return 0
        }
        
        return subscription.featureTitles.count
    }
    
    private func show(error: ProductServiceError) {
        SVProgressHUD.showError(withStatus: error.localizedDescription)
        logger.log(error)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let product = self.productService.selectedProduct else {
            return UITableViewCell()
        }
        
        if indexPath.section == Section.price.rawValue {
            
            let cell: SubscriptionPriceCell = tableView.dequeueReusableCell(indexPath: indexPath)
            
            cell.subscriptionTitleLabel.text = product.title + " subscription"
            cell.subscriptionPriceLabel.text = product.price
            cell.descriptionLabel.text = product.payForText

            return cell
            
        } else if indexPath.section == Section.details.rawValue {
            
            let cell: SubscriptionInfoCell = tableView.dequeueReusableCell(indexPath: indexPath)
            
            let text = product.featureTitles[indexPath.row]
            cell.setup(text: text, isBought: product.isBought)
            
            return cell
            
        } else {
            
            let cell: BuySubscriptionCell = tableView.dequeueReusableCell(indexPath: indexPath)
            self.paymantCell = cell
            
            cell.setup(isBought: product.isBought, discount: product.discount, topText: product.description)
            cell.buySelectedClosure = { [weak self] in
                guard let `self` = self else { return }
                
                SVProgressHUD.show()
                
                self.isInPaymantProgress = true
                self.productService.buy(product: product) { error in
                    SVProgressHUD.dismiss()
                    
                    if let error = error {
                        self.show(error: error)
                    } else {
                        self.completionAction?(self)
                    }
                    
                    self.isInPaymantProgress = false
                }
            }
            
            return cell
        }
    }
}
