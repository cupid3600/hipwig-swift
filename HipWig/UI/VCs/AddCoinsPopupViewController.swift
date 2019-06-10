//
//  AddCoinsPopupViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/24/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD

class AddCoinsPopupViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var discountLabel: UILabel!
    @IBOutlet private weak var coinsLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
//    @IBOutlet private weak var creditTypeCollectionView: UICollectionView!
    @IBOutlet private weak var addCallCreditsButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var coinDescriptionContainerView: UIView!
    @IBOutlet private weak var priceContainerView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var purchaseActivityIndicatorView: UIActivityIndicatorView!
    
    //MARK: - Properties -
//    private let minimumInteritemSpacingForSectionAt: CGFloat = 5.0.adjusted
    private let productService: ProductService = ProductServiceImplementation.default
    private var selectedIndex: Int? {
        didSet {
            self.addCallCreditsButton.isEnabled = self.selectedIndex != nil
        }
    }
    
    //MARK: - Interface -
    var completion: ((Bool) -> Void)?
    var titleText: String!
    var detailsText: String!
    
    private var inPurchaseProgress: Bool = false {
        didSet {
            if inPurchaseProgress {
                self.purchaseActivityIndicatorView.startAnimating()
            } else {
                self.purchaseActivityIndicatorView.stopAnimating()
            }
        }
    }
    
    private var isLoadingProductList: Bool = false {
        didSet {
            if isLoadingProductList {
                self.activityIndicatorView.startAnimating()
            } else {
                self.activityIndicatorView.stopAnimating()
            }
        }
    }
    private let api: RequestsManager = RequestsManager.manager
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reachability.add(reachabylityDelegate: self)
        self.view.backgroundColor = .clear
        
        self.showAnimate(with: self.containerView)
        
        self.titleLabel.text = self.titleText
        self.descriptionLabel.text = self.detailsText
        
        self.selectedIndex = nil
        self.inPurchaseProgress = false
        self.fetchProductList()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        reachability.remove(reachabylityDelegate: self)
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Actions -
    @IBAction func addCallCreditsSelected(_ sender: UIButton) {
        self.makePurchase()
    }
    
    override func backDidSelect(_ sender: UIButton) {
        if let completion = self.completion {
            self.removeAnimate(with: self.containerView) {
                completion(false)
            }
        }
    }
    
    //MARK: - Private -
    override func service(_ service: ReachabilityService, didChangeNetworkState isNetworkReachable: Bool) {
        if isNetworkReachable {
            self.fetchProductList()
            
            self.selectedIndex = nil
            self.inPurchaseProgress = false
        }
    }
    
    private func onLoad() {
        self.setup(titleLabel: self.titleLabel)
        self.setup(descriptionLabel: self.descriptionLabel)
        self.setup(addCallCreditsButton: self.addCallCreditsButton)
        self.setup(containerView: self.containerView)
        self.setup(coinDescriptionContainerView: self.coinDescriptionContainerView)
        self.setup(priceContainerView: self.priceContainerView)
        self.setup(priceLabel: self.priceLabel)
        self.setup(coinsLabel: self.coinsLabel)
        self.setup(discountLabel: self.discountLabel)
        
        self.view.adjustConstraints()
        
        NotificationCenter.addProductPurchaseFailedObserver { [weak self] result in
            guard let `self` = self else { return }
            
            self.isLoadingProductList = false
            self.inPurchaseProgress = false
            
            if let error = result.error {
                self.show(error: error)
            }
        }
        
        NotificationCenter.addProductPurchaseCanceledObserver { [weak self] indentifier in
            guard let `self` = self else { return }
            
            self.isLoadingProductList = false
            self.inPurchaseProgress = false
            
            analytics.log(.cancelPurchase(product: indentifier))
        }
    }
    
    private func fetchProductList() {
//        self.activityIndicatorView.startAnimating()
        self.productService.fetchProductList(ofType: .product) { [weak self] _ in
//            guard let `self` = self else { return }
            
//            self.isLoadingProductList = false
//            self.creditTypeCollectionView.reloadData()
//
//            if let index = self.selectedIndex {
//                let indexPath = IndexPath(row: index, section: 0)
//                self.creditTypeCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
//            }
        }
    }
    
    private func makePurchase() {
        if let selectedIndex = self.selectedIndex {
            let product = self.productService[selectedIndex]
            
            self.inPurchaseProgress = true
            self.productService.buy(product: product) { [weak self] error in
                guard let `self` = self else { return }
                
                self.inPurchaseProgress = false
                
                if let error = error {
                    self.show(error: error)
                } else {
                    if let completion = self.completion {
                        self.removeAnimate(with: self.containerView) {
                            completion(true)
                        }
                    } else {
                        self.removeAnimate(with: self.containerView)
                    }
                }
            }
        }
    }
    
    private func show(error: Error) {
        SVProgressHUD.showError(withStatus: error.localizedDescription)
        logger.log(error)
    }
    
    private func setup(containerView view: UIView) {
        view.layer.borderWidth = 1.adjusted
        view.layer.borderColor = UIColor(red: 255, green: 79, blue: 154).cgColor
    }
    
    private func setup(coinDescriptionContainerView view: UIView) {
        view.layer.cornerRadius = 8.adjusted
        view.backgroundColor = UIColor(red: 47, green: 34, blue: 54)
    }
    
    private func setup(priceContainerView view: UIView) {
        view.layer.cornerRadius = 8.adjusted 
    }
    
//    private func setup(collectionView: UICollectionView) {
//        collectionView.registerNib(with: CallCreditCell.self)
//    }
    
    private func setup(coinsLabel label: UILabel) {
        label.font = Font.regular.of(size: 20)
        label.textAlignment = .center
        label.textColor = .white
    }

    private func setup(discountLabel label: UILabel) {
        label.font = Font.regular.of(size: 20)
        label.textAlignment = .center
        label.textColor = UIColor(red: 255, green: 226, blue: 122)
    }
    
    private func setup(titleLabel label: UILabel) {
        label.font = Font.regular.of(size: 24)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(priceLabel label: UILabel) {
        label.font = Font.regular.of(size: 20)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(descriptionLabel label: UILabel) {
        label.font = Font.light.of(size: 16)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(addCallCreditsButton button: UIButton) {
        button.titleLabel?.font = Font.bold.of(size: 16)
        button.tintColor = textColor2
        button.adjustsImageWhenHighlighted = false
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 255, green: 79, blue: 154)
        button.layer.cornerRadius = 8.0.adjusted
        button.clipsToBounds = true
    }
}


////MARK: - UICollectionViewDelegate
//extension AddCoinsPopupViewController: UICollectionViewDelegate {
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        self.selectedIndex = indexPath.row
////        self.creditTypeCollectionView.reloadData()
//    }
//}
//
////MARK: - UICollectionViewDataSource
//extension AddCoinsPopupViewController: UICollectionViewDataSource {
//
//    func collectionView(_ collectionView: UICollectionView,
//                        numberOfItemsInSection section: Int) -> Int {
//        return self.productService.productCount
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//
//        let cell: CallCreditCell = collectionView.dequeueReusableCell(indexPath: indexPath)
//
//        cell.product = self.productService[indexPath.row]
//        cell.isSelected = self.isSelectedByDefault(for: indexPath.row)
//
//        return cell
//    }
//
//    private func isSelectedByDefault(for index: Int) -> Bool {
//        if let selectedIndex = self.selectedIndex {
//            return index == selectedIndex
//        } else {
//            let byDefaultIndex = Int((Double(self.productService.productCount) / 2.0).rounded(.down))
//            let result = index == byDefaultIndex
//            if result {
//                self.selectedIndex = index
//            }
//
//            return result
//        }
//    }
//}
//
////MARK: - UICollectionViewDelegateFlowLayout
//extension AddCoinsPopupViewController: UICollectionViewDelegateFlowLayout {
//
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return self.minimumInteritemSpacingForSectionAt
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return self.minimumInteritemSpacingForSectionAt
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: collectionView.bounds.width / 3.0 - self.minimumInteritemSpacingForSectionAt,
//                      height: collectionView.bounds.height)
//    }
//}

