//
//  ExpertsListViewController.swift
//  HipWig
//
//  Created by Alexey on 1/16/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

struct ExpertsFilter: Codable {
    
    var purpose: Purpose?
    var sex: Sex?
    var location: Location?
    
    mutating func reset() {
        purpose = nil
        sex = nil
        location = nil
    }
    
    var hasFilterValue: Bool {
        return purpose != nil || sex != nil || location != nil
    }
}

class ExpertsListViewController: BaseViewController {
    
    //MARK: - Outlets -
    @IBOutlet weak private var collectionView: UICollectionView!
    @IBOutlet weak private var filterButton: UIButton!
    @IBOutlet weak private var filterViewHeight: NSLayoutConstraint!
    @IBOutlet weak private var filterViewSeparatorHeight: NSLayoutConstraint!
    @IBOutlet weak private var purposeSegment: SelectPosposeView!
    @IBOutlet weak private var sexSegment: SelectGenderView!
    @IBOutlet weak private var locationSegment: SelectLocationView!
    @IBOutlet private var filters: [LittleOptionSegment]!
    @IBOutlet weak private var filterStackView: UIStackView!
    @IBOutlet private var refreshTableActivityIndicator: UIActivityIndicatorView!
    
    //MARK: - Properties -
    private var filter: ExpertsFilter = UserDefaults.filter {
        didSet {
            UserDefaults.filter = filter
        }
    } 
    private var pagination: Pagination = .default
    private let playVideoService: PlayVideoService = PlayVideoServiceImplementation()
    private let account: AccountManager = AccountManager.manager
    private let refreshControl = UIRefreshControl()
    private let api: RequestsManager = RequestsManager.manager
    private var showRefreshAnimation: Bool = false {
        didSet {
            if showRefreshAnimation {
                self.refreshTableActivityIndicator.startAnimating()
            } else {
                self.refreshTableActivityIndicator.stopAnimating()
            }
        }
    }
    private let storage: ExpertLocalStorage = ExpertLocalStorageImplementation.default
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.playVideoService.setup(delegate: self)
        self.collectionView.registerNib(with: ExpertListCell.self)

        self.setup(purposeSegment: self.purposeSegment)
        self.setup(sexSegment: self.sexSegment)
        self.setup(locationSegment: self.locationSegment)
        self.setup(refreshControl: self.refreshControl)
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            if MainStoryboard.mainScreenAsTabBar {
                self.collectionView.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
            } else {
                self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            }
        } else {
            let guide = self.bottomLayoutGuide
            if MainStoryboard.mainScreenAsTabBar {
                self.collectionView.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
            } else {
                self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            }
        }
        
        if #available(iOS 10.0, *) {
            self.collectionView.refreshControl = self.refreshControl
        } else {
            self.collectionView.addSubview(self.refreshControl)
        }
        
        self.collectionView.addInfiniteScroll { [weak self] collectionView in
            guard let `self` = self else { return }
            
            self.fetchMoreExperts { result in
                switch result {
                case .success(let indexPaths):
                    if let indexPathsToInsert = indexPaths {
                        collectionView.performBatchUpdates({
                            collectionView.insertItems(at: indexPathsToInsert)
                        })
                    }
                case .failure(let error):
                    logger.log(error)
                }
                
                collectionView.finishInfiniteScroll()
            }
        }
        
        self.collectionView.setShouldShowInfiniteScrollHandler { [weak self] _ in
            guard let `self` = self else { return false }
            
            return self.pagination.hasNextPage
        }
        
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.view.adjustConstraints()
        
        self.updateViewWithFeatureFlags()
        self.loadExperts(filter: self.filter)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.toggleFilterView(opened: false, animated: false)
        
        self.refreshControl.endRefreshing()
        
        if self.storage.experts.isEmpty {
            self.showRefreshAnimation = true
        }
        
        analytics.log(.open(screen: .expertList))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.playVideoService.pauseSession()
        self.filterButton?.isSelected = false
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Actions -
    @IBAction private func filterButtonToggled(sender: UIButton) {
        sender.isSelected.toggle()
        
        self.toggleFilterView(opened: sender.isSelected, animated: true)
    }

    //MARK: - Private -
    private func updateViewWithFeatureFlags() {
        let category = ExpertListFeatureCategoryImplementation.default
        
        self.locationSegment.isHidden = !category.locationFilterEnabled
        self.sexSegment.isHidden = !category.genderFilterEnabled
        self.purposeSegment.isHidden = !category.workTypeFilterEnabled
        self.filterButton.isHidden = !category.filtersEnabled
        self.playVideoService.shouldPlay = category.playExpertsVideoEnabled
    }
    
    private func setup(refreshControl: UIRefreshControl) {
        refreshControl.addTarget(self, action: #selector(pullToReffreshExpertList), for: .valueChanged)
        refreshControl.tintColor = textColor2
    }
    
    @objc private func pullToReffreshExpertList() {
        self.loadExperts(filter: self.filter)
    }
    
    private func setup(purposeSegment: SelectPosposeView) {
        purposeSegment.optionViewDelegate = self
        
        if let purpose = self.filter.purpose {
            purposeSegment.selectSegment(purpose.rawValue)
        }
    }
    
    private func setup(sexSegment: SelectGenderView) {
        sexSegment.optionViewDelegate = self
        
        if let sex = self.filter.sex {
            sexSegment.selectSegment(sex.rawValue)
        }
    }
    
    private func setup(locationSegment: SelectLocationView) {
        locationSegment.optionViewDelegate = self
        
        if let location = self.filter.location {
            locationSegment.selectSegment(location.rawValue)
        }
    }
    
    private func loadExperts(filter: ExpertsFilter) {
        self.pagination = .default
        self.pagination.isFetching = true
        
        self.storage.fetchExperts(filter: filter, pagination: self.pagination) { [weak self] result in
            switch result {
            case .success(let data):
                self?.pagination = data.pagination
            case .failure(let error):
                logger.log(error)
            }
            
            self?.pagination.isFetching = false
            self?.showRefreshAnimation = false
            self?.refreshControl.endRefreshing()
            self?.collectionView.reloadData()
        }
    }
    
    private func fetchMoreExperts(completion: @escaping ValueHandler<[IndexPath]?>) {
        if !self.pagination.hasNextPage || self.pagination.isFetching {
            return
        }
        
        self.pagination.isFetching = true
        self.pagination.calculateNextPage()
        
        self.storage.fetchMoreExperts(filter: self.filter, pagination: self.pagination) { [weak self] result in
            switch result {
            case .success(let data):
                self?.pagination = data.pagination
                
                completion(.success(data.indexPaths))
            case .failure(let error):
                self?.pagination.isFetching = false
                completion(.failure(error))
            }
        }
    }
    
    private func toggleFilterView(opened: Bool, animated: Bool) {
        var alphaValue: CGFloat = 0.0
        
        let filterHeight: CGFloat = 52.0.adjusted
        let filterOffset: CGFloat = 20.0.adjusted
        let filterCount = CGFloat(filters.filter{ !$0.isHidden }.count)
        self.filterStackView.spacing = filterCount == 0 ? 0 : filterOffset
        
        if opened {
            self.filterViewHeight.constant = (filterCount * filterHeight) + ((filterCount - 1) * filterOffset)
            self.filterViewSeparatorHeight.constant = 20.0.adjusted
            alphaValue = 1.0
        } else {
            self.filterViewHeight.constant = 0.0
            self.filterViewSeparatorHeight.constant = 0.0
            alphaValue = 0.0
        }

        let duration = animated ? 0.25 : 0.0
        UIView.animate(withDuration: duration) {
            self.purposeSegment.alpha = alphaValue
            self.sexSegment.alpha = alphaValue
            self.locationSegment.alpha = alphaValue
            
            self.view.layoutIfNeeded()
        }
    }
    
    private func reloadView() {
        self.storage.clean()
        self.pagination = .default
        self.collectionView.reloadData()
    }
}

//MARK: - UICollectionViewDelegate
extension ExpertsListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let expert = self.storage[indexPath.row]
        
        analytics.log(.open(screen: .expert(name: expert.name)))
        MainStoryboard.showExpertProfile(from: self, expert: expert)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        
        self.playVideoService.recreateSession()
    }
}

//MARK: - UICollectionViewDataSource
extension ExpertsListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
//        if self.storage.count == 0 && !self.pagination.isFetching {
//            if let view = EmptyExpertListView.fromXib() {
//                collectionView.setEmptyView(view: view)
//            }
//        } else {
//            collectionView.restoreEmptyView()
//        }
//        
        return self.storage.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ExpertListCell = collectionView.dequeueReusableCell(indexPath: indexPath)
        
        let user = self.storage[indexPath.row]
        cell.setup(user: user) 
        
        self.playVideoService.recreateSession()
        
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension ExpertsListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding: CGFloat = 24.adjusted
        let collectionViewSize = collectionView.frame.size.width - padding
        
        return CGSize(width: collectionViewSize / 2, height: 200.adjusted)
    }
}

//MARK: - UIScrollViewDelegate
extension ExpertsListViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.playVideoService.scrollViewWillBeginDragging?(scrollView)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.playVideoService.scrollViewWillBeginDecelerating?(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.playVideoService.scrollViewDidEndDecelerating?(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.playVideoService.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
}

//MARK: - LittleOptionSegmentDelegate
extension ExpertsListViewController: LittleOptionSegmentDelegate {
    
    func segmentView(_ segmentView: LittleOptionSegment, didSelectItemWithIndex index: Int) {
        if segmentView == purposeSegment {
            self.filter.purpose = Purpose(rawValue: index)
        } else if segmentView == sexSegment {
            self.filter.sex = Sex(rawValue: index)
        } else if segmentView == locationSegment {
            self.filter.location = Location(rawValue: index)
        }
        
        self.showRefreshAnimation = true
        self.loadExperts(filter: self.filter)
        
        analytics.log(.select(filter: self.filter))
    }
    
    func segmentView(_ segmentView: LittleOptionSegment, didDeselectItemWithIndex index: Int) {
        if segmentView == purposeSegment {
            self.filter.purpose = nil
        } else if segmentView == sexSegment {
            self.filter.sex = nil
        } else if segmentView == locationSegment {
            self.filter.location = nil
        }
        
        self.showRefreshAnimation = true
        self.loadExperts(filter: self.filter)
        
        analytics.log(.select(filter: self.filter))
    }
}

//MARK: - PlayVideoServiceDelegate
extension ExpertsListViewController : PlayVideoServiceDelegate {
    
    var workFrame: CGRect {
        return self.collectionView.frame
    }
    
    var displayingVideoCells: [VideoCell] {
        return self.collectionView.visibleCells.compactMap{ $0 as? ExpertListCell }
    }
}

private let userFiltersKey = "userFiltersKeyValue"
extension UserDefaults {
    
    class var filter: ExpertsFilter {
        get {
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.data(forKey: userFiltersKey) {
                do {
                    let filter: ExpertsFilter = try decoder.decode(ExpertsFilter.self, from: data)
                    return filter
                } catch {
                    return ExpertsFilter()
                }
            } else {
                return ExpertsFilter()
            }
        }
        
        set {
            let coder = JSONEncoder()
            do {
                let data = try coder.encode(newValue)
                UserDefaults.standard.set(data, forKey: userFiltersKey)
                
                UserDefaults.standard.synchronize()
            } catch {
                logger.log(error)
            }
        }
    }
}
