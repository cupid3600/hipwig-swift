//
//  AddCallCreditsPopupViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/5/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD

class AddCallCreditsPopupViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var cancelCallLabel: UILabel!
    @IBOutlet private weak var addCallCreditsLabel: UILabel!
    @IBOutlet private weak var leftMinutesLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var creditTypeCollectionView: UICollectionView!
    @IBOutlet private weak var addCallCreditsButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var purchaseActivityIndicatorView: UIActivityIndicatorView!
    
    //MARK: - Properties -
    private let minimumInteritemSpacingForSectionAt: CGFloat = 5.0.adjusted
    private let productService: ProductService = ProductServiceImplementation.default
    private var selectedIndex: Int? {
        didSet {
            self.addCallCreditsButton.isEnabled = self.selectedIndex != nil
        }
    }
    
    //MARK: - Interface -
    var completion: ((Bool) -> Void)?
    var callThreshold: CallThreshold?
    var whileInCallingState: Bool = false
    var callCaption: String?
    var inPurchaseProgress: Bool = false {
        didSet {
            if inPurchaseProgress {
                self.purchaseActivityIndicatorView.startAnimating()
            } else {
                self.purchaseActivityIndicatorView.stopAnimating()
            }
        }
    }
    
    var isLoadingProductList: Bool = false {
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
        
        self.view.backgroundColor = .clear
        self.showAnimate(with: self.containerView)
        
        if self.callCaption != nil {
            self.leftMinutesLabel.text = self.callCaption
        } else {
            if let callThreshold = self.callThreshold {
                self.leftMinutesLabel.text = callThreshold.title
            }
        }
        
        if let callThreshold = self.callThreshold {
            self.leftMinutesLabel.text = callThreshold.title
        }
        
        self.cancelCallLabel.isHidden = !self.whileInCallingState
        
        self.fetchProductList()
        
        self.selectedIndex = nil
        self.inPurchaseProgress = false
        reachability.add(reachabylityDelegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.remove(reachabylityDelegate: self)
    }
    
    override func backDidSelect(_ sender: UIButton) {
        if let completion = self.completion {
            self.removeAnimate(with: self.containerView) {
                completion(false)
            }
        }
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Actions -
    @IBAction func addCallCreditsSelected(_ sender: UIButton) {
        self.makePurchase()
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
        self.setup(collectionView: self.creditTypeCollectionView)
        self.setup(cancelCallLabel: self.cancelCallLabel)
        self.setup(addCallCreditsLabel: self.addCallCreditsLabel)
        self.setup(leftMinutesLabel: self.leftMinutesLabel)
        self.setup(descriptionLabel: self.descriptionLabel)
        self.setup(addCallCreditsButton: self.addCallCreditsButton)
        self.setup(containerView: self.containerView)
        
        self.view.adjustConstraints() 
    }
    
    private func fetchProductList() {
        self.activityIndicatorView.startAnimating()
        self.productService.fetchProductList(ofType: .product) { [weak self] _ in
            guard let `self` = self else { return }

            self.isLoadingProductList = false
            self.creditTypeCollectionView.reloadData()
            
            if let index = self.selectedIndex {
                let indexPath = IndexPath(row: index, section: 0)
                self.creditTypeCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            }
        }
        
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
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 255, green: 79, blue: 154).cgColor
    }
    
    private func setup(collectionView: UICollectionView) {
        collectionView.registerNib(with: CallCreditCell.self)
    }
    
    private func setup(cancelCallLabel label: UILabel) {
        label.font = Font.regular.of(size: 24)
        label.textColor = .white
        label.textAlignment = .center
    }
    
    private func setup(addCallCreditsLabel label: UILabel) {
        label.font = Font.regular.of(size: 24)
        label.textColor = .white
        label.textAlignment = .center
    }
    
    private func setup(leftMinutesLabel label: UILabel) {
        label.font = Font.regular.of(size: 36)
        label.textAlignment = .center
        label.textColor = UIColor(red: 255, green: 79, blue: 154)
    }
    
    private func setup(descriptionLabel label: UILabel) {
        label.font = Font.light.of(size: 16)
        label.textAlignment = .center
        label.textColor = .white
    }
    
    private func setup(addCallCreditsButton button: UIButton) {
        button.titleLabel?.font = Font.light.of(size: 16)
        button.tintColor = textColor2
        button.adjustsImageWhenHighlighted = false
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 255, green: 79, blue: 154)
        button.layer.cornerRadius = 8.0.adjusted
        button.clipsToBounds = true
    }
}


//MARK: - UICollectionViewDelegate
extension AddCallCreditsPopupViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        self.creditTypeCollectionView.reloadData()
    }
}

//MARK: - UICollectionViewDataSource
extension AddCallCreditsPopupViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.productService.productCount
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: CallCreditCell = collectionView.dequeueReusableCell(indexPath: indexPath)
        
        cell.product = self.productService[indexPath.row]
        cell.isSelected = self.isSelectedByDefault(for: indexPath.row)
        
        return cell
    }
    
    private func isSelectedByDefault(for index: Int) -> Bool {
        if let selectedIndex = self.selectedIndex {
            return index == selectedIndex
        } else {
            let byDefaultIndex = Int((Double(self.productService.productCount) / 2.0).rounded(.down))
            let result = index == byDefaultIndex
            if result {
                self.selectedIndex = index
            }
            
            return result
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension AddCallCreditsPopupViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.minimumInteritemSpacingForSectionAt
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.minimumInteritemSpacingForSectionAt
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width / 3.0 - self.minimumInteritemSpacingForSectionAt,
                      height: collectionView.bounds.height)
    }
}
