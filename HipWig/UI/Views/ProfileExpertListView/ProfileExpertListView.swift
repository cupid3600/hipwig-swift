//
//  ProfileExpertListView.swift
//  HipWig
//
//  Created by Alexey on 1/22/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol ProfileExpertListViewDelegate: class {
    func view(_ view: ProfileExpertListView, didSelectExpert user: User)
}

class ProfileExpertListView: UIView {

    //MARK: - Outltes -
    @IBOutlet private var collectionView: UICollectionView!

    //MARK: - Properties -
    public weak var delegate: ProfileExpertListViewDelegate?
    private var indexOfCellBeforeDragging = 0
    private var currentIndex = 0
    private var experts: [User] = []
    private var currentExpert: User!
    private var cellHeight: CGFloat {
//        let height = 85.0.adjusted
//        if self.collectionView.bounds.height < height {
            return self.collectionView.bounds.height - self.cellInset
//        } else {
//            return height
//        }
    }
    
    private var cellInset: CGFloat {
        return 12.0.adjusted
    }
    
    //MARK: - Life Cycle -
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        if let view = ProfileExpertListView.fromXib(owner: self) {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.place(view)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.collectionView.registerNib(with: ProfileExpertListCollectionCell.self)
        self.adjustConstraints()
    }
    
    //MARK: - Private -
    public func setup(experts: [User], currentID: String) {
        self.experts = experts
        self.collectionView.reloadData()

        let currentExpertIndexes = self.experts.enumerated().filter{ currentID == $0.element.id }.map{ $0.offset }
        
        guard !currentExpertIndexes.isEmpty else { return }
        
        let indexPath = IndexPath(row: currentExpertIndexes.last!, section: 0)
        self.currentExpert = experts[indexPath.row]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animateCollectionViewCells(false)
            }
        }
    }

    public func animateCollectionViewCells(_ animated: Bool) {
        if let cells = self.collectionView.visibleCells as? [ProfileExpertListCollectionCell] {
            let duration = animated ? 0.25 : 0.0

            for cell in cells {
                var alpha: CGFloat = ProfileExpertListCollectionCell.inactiveAlpha
                if self.currentExpert.id == cell.getExpertID() {
                    alpha = 1.0
                }
                
                UIView.animate(withDuration: duration) {
                    cell.imageView.alpha = alpha
                }
            }
        }
    }
}

//MARK: - UICollectionViewDelegate
extension ProfileExpertListView: UICollectionViewDelegate {
    
}

//MARK: - UICollectionViewDataSource
extension ProfileExpertListView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.experts.count
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let castedCell = cell as? ProfileExpertListCollectionCell {
            if self.currentExpert.id == castedCell.getExpertID() {
                castedCell.imageView.alpha = 1.0
            } else {
                castedCell.imageView.alpha = ProfileExpertListCollectionCell.inactiveAlpha
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ProfileExpertListCollectionCell = collectionView.dequeueReusableCell(indexPath: indexPath)
        
        let expert = self.experts[indexPath.row]
        cell.setup(expert: expert)
        
        return cell
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    private var indexOfMajorCell: Int {
        let itemWidth: CGFloat = self.cellHeight
        let proportionalOffset = self.collectionView.contentOffset.x / itemWidth
        let index = Int(round(proportionalOffset))
        let numberOfItems = self.collectionView.numberOfItems(inSection: 0)
        
        return max(0, min(numberOfItems - 1, index))
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.indexOfCellBeforeDragging = self.indexOfMajorCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        self.indexOfCellBeforeDragging = indexPath.row//self.indexOfMajorCell
        
        self.performScroll(index: indexPath.row, velocity: CGPoint(x: 0.5, y: 0.0), scrollView: collectionView)
    }
    
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let index = self.indexOfMajorCell
//
//        let indexPath = IndexPath(row: index, section: 0)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
//            self.collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.transiteToCurrentExpert(animated: true)
//                self.performScroll(index: index, velocity: CGPoint(x: 0.5, y: 0.0), scrollView: scrollView)
//            }
//        }
//    }
    
    private func performScroll(index: Int, velocity: CGPoint, scrollView: UIScrollView) {
        let dataSourceCount = collectionView(collectionView!, numberOfItemsInSection: 0)
        let swipeVelocityThreshold: CGFloat = 0.8 // after some trail and error
        let hasEnoughVelocityToSlideToTheNextCell = self.indexOfCellBeforeDragging + 1 < dataSourceCount && velocity.x > swipeVelocityThreshold
        let hasEnoughVelocityToSlideToThePreviousCell = self.indexOfCellBeforeDragging - 1 >= 0 && velocity.x < -swipeVelocityThreshold
        let majorCellIsTheCellBeforeDragging = index == self.indexOfCellBeforeDragging
        let didUseSwipeToSkipCell = majorCellIsTheCellBeforeDragging && (hasEnoughVelocityToSlideToTheNextCell || hasEnoughVelocityToSlideToThePreviousCell)
        
        if didUseSwipeToSkipCell {
            
            let snapToIndex = self.indexOfCellBeforeDragging + (hasEnoughVelocityToSlideToTheNextCell ? 1 : -1)
            let toValue = self.cellHeight * CGFloat(snapToIndex)
            
            self.currentIndex = snapToIndex
            
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: velocity.x,
                           options: .allowUserInteraction,
                           animations: {
                scrollView.contentOffset = CGPoint(x: toValue, y: 0)
                scrollView.layoutIfNeeded()
            }, completion: nil)
            
        } else {
            self.currentIndex = index
            
            let indexPath = IndexPath(row: index, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
        self.handleExpertChanging()
//        })
    }

    private func handleExpertChanging() {
        if self.currentIndex > self.experts.count {
            return
        }
        
        let expert = self.experts[self.currentIndex]

        self.currentExpert = expert

//        if self.indexOfCellBeforeDragging != self.currentIndex {
            self.delegate?.view(self, didSelectExpert: expert)
//        } else {
//            print("")
//        }
        
        self.animateCollectionViewCells(true)
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension ProfileExpertListView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: self.cellHeight, height: self.cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        var inset: CGFloat = 0.0
        inset = (UIScreen.main.bounds.width - self.cellHeight) * 0.5
        inset = max(inset, 0.0)
        
        return UIEdgeInsets(top: 0.0, left: inset, bottom: 0.0, right: inset)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0//self.cellInset
    }
}
