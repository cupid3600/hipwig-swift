//
//  ChooseInstagramPhotoViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol ChooseInstagramPhotoViewControllerDelegate: class {
    func didSelectImage(imageURL url: URL)
}

private struct InstragramPagination {
    let defaultPictureCountToFetch = 10
    
    var pictureCountToFetch: Int {
        let leftMedias = total - currentFetched
        if leftMedias > defaultPictureCountToFetch {
            return defaultPictureCountToFetch
        } else {
            return leftMedias
        }
    }
    
    var hasNextPage: Bool {
        return currentFetched < total
    }
    
    var isFetching: Bool = false
    var total: Int = 0
    var currentFetched: Int = 0
}

class ChooseInstagramPhotoViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK: - Properties -
    weak var delegate: ChooseInstagramPhotoViewControllerDelegate?
    
    private let api = Instagram.shared
    private var medias: [InstagramMedia] = []
    private var pagination: InstragramPagination = InstragramPagination()
    
    //MARK: - Life cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(collectionView: self.collectionView)
        self.fetchUser { [weak self] totalCount in
            self?.pagination.total = totalCount
            self?.fetchInstagramPhotos()
        } 
    }
    
    private func fetchUser(completion: @escaping (Int) -> Void) {
        api.user("self", success: { user in
            completion(user.counts?.media ?? 0)
        }) { error in
            logger.log(error)
        }
    }
    
    private func fetchInstagramPhotos() {
        self.pagination.isFetching = true
        
        self.activityIndicator.startAnimating()
        self.api.recentMedia(fromUser: "self", count: self.pagination.pictureCountToFetch, success: { [weak self] medias in
            guard let `self` = self else { return }

            self.medias = medias
            self.pagination.currentFetched = self.medias.count
            self.pagination.isFetching = false
            
            self.activityIndicator.stopAnimating()
            self.collectionView.reloadData()
        }) { error in
            self.activityIndicator.stopAnimating()
            logger.log(error)
        }
    }
    
    private func setup(collectionView: UICollectionView) {
        collectionView.registerNib(with: InstargamPreviewPhotoCollectionCell.self)
        collectionView.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 0, right: 0)
        
        self.collectionView.addInfiniteScroll { [weak self] collectionView in
            guard let `self` = self else { return }
            
            self.fetchMorePictures {
                collectionView.finishInfiniteScroll()
            }
        }
        
        self.collectionView.setShouldShowInfiniteScrollHandler { (colelctionView) -> Bool in
            return self.pagination.hasNextPage
        }
    }
    
    private func fetchMorePictures(completion: @escaping () -> Void) {
        guard self.pagination.hasNextPage, !self.pagination.isFetching else { return }
        
        self.pagination.isFetching = true
        self.api.recentMedia(fromUser: "self", maxId: self.medias.last?.id, minId: nil, count: self.pagination.pictureCountToFetch, success: { [weak self] medias in
            
            guard let `self` = self else { return }
            
            let prevCount = self.medias.count
            self.medias.append(contentsOf: medias)
            let newCount = self.medias.count
            
            if prevCount != newCount {
                let indexPaths = (prevCount ..< newCount).map { IndexPath(row: $0, section: 0) }
                self.collectionView.performBatchUpdates({
                    self.collectionView.insertItems(at: indexPaths)
                })
            }
            
            self.pagination.currentFetched = self.medias.count
            self.pagination.isFetching = false
            
            completion()

        }) { [weak self] error in
            guard let `self` = self else { return }
            
            logger.log(error)
            self.pagination.isFetching = false
            
            completion()
        }
    }
}

//MARK: - UICollectionViewDelegate
extension ChooseInstagramPhotoViewController : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let media = medias[indexPath.row]
        self.delegate?.didSelectImage(imageURL: media.images.standardResolution.url)
        
        self.navigationController?.popViewController(animated: true)
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension ChooseInstagramPhotoViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 24
        let collectionViewSize = collectionView.frame.size.width - padding
        
        return CGSize(width: collectionViewSize / 2, height: collectionViewSize / 2)
    }
}

//MARK: - UICollectionViewDataSource
extension ChooseInstagramPhotoViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: InstargamPreviewPhotoCollectionCell = collectionView.dequeueReusableCell(indexPath: indexPath)
        let media = self.medias[indexPath.row]
        cell.update(with: media.images.standardResolution.url)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.medias.count
    }
}
