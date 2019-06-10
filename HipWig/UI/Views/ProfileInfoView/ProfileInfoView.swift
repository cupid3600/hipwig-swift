//
//  ProfileInfoView.swift
//  HipWig
//
//  Created by Alexey on 1/22/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Device_swift

class ProfileInfoView: UIView {
    
    //MARK: - Outlets -
    @IBOutlet private var leftSkillView: SkillView?
    @IBOutlet private var centerSkillView: SkillView?
    @IBOutlet private var rightSkillView: SkillView?
    @IBOutlet private var followersLabel: UILabel!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var pagesControl: UIPageControl!
    @IBOutlet private var contantHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var contantStackView: UIStackView!

    //MARK: - Properties -
    private var comments: [String] = []
    private var skillButtons: [SkillView] {
        return [self.leftSkillView, self.centerSkillView, self.rightSkillView].compactMap { $0 }
    }
    
    public var isLoadign: Bool = false {
        didSet {
            if isLoadign {
                self.loadingIndicatorView.startAnimating()
            } else {
                self.loadingIndicatorView.stopAnimating()
            }
        }
    }
    
    //MARK: - Life Cycle -
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        if let viewFromXIB = ProfileInfoView.fromXib(owner: self) {
            self.place(viewFromXIB)
        }
        
        self.loadingIndicatorView.stopAnimating()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setup(skillButons: self.skillButtons)
        self.followersLabel?.font = Font.regular.of(size: 16)
        self.setup(collectionView: self.collectionView)
        self.contantStackView.spacing = 12.adjusted
        self.pagesControl?.alpha = 0.0
        self.adjustConstraints()
    }
    
    //MARK: - Private -
    private func setup(collectionView: UICollectionView) {
        collectionView.backgroundColor = disabledColor
        collectionView.layer.cornerRadius = 8
        collectionView.registerNib(with: ProfileCommentCollectionCell.self)
    }
    
    private func setup(skillButons buttons: [SkillView]) {
        buttons.forEach { button in
            button.alpha = 0.0
        }
    }

    public func setEmptyData() {
        self.skillButtons.forEach { button in
            button.alpha = 0.0
        }

        self.comments = []
        self.updateView(alpha: 0.0)
    }
    
    private func updateView(alpha: CGFloat) {
        self.collectionView?.alpha = alpha
        self.pagesControl?.alpha = alpha
        self.followersLabel?.alpha = alpha
    }

    public func setup(user: User) {
        
        self.comments = user.reviews.map{ $0.message }
        self.pagesControl?.numberOfPages = user.reviews.count
        self.collectionView?.reloadData()
        
        self.followersLabel?.text = "Followers: " + String(user.expert?.followers ?? 0)
        
        if let skills = user.expert?.skills, !skills.isEmpty {
            if skills.count < skillButtons.count {
                for (index, view) in skillButtons.enumerated() {
                    if (index < skills.count) {
                        let skill = skills[index]
                        view.isHidden = false
                        view.update(skillName: skill.title, skillIcon: skill.defaultImage)
                    } else {
                        view.isHidden = true
                    }
                }
            } else {
                for (index, skill) in skills.enumerated() {
                    self.skillButtons[index].isHidden = false
                    self.skillButtons[index].update(skillName: skill.title, skillIcon: skill.defaultImage)
                }
            }
        } else {
            self.skillButtons.forEach { button in
                button.isHidden = true
            }
        } 

        UIView.animate(withDuration: 0.25) {
            self.skillButtons.forEach { button in
                button.alpha = 1.0
            }
            
            self.updateView(alpha: 1.0)
        }
    }
}

//MARK: - UICollectionViewDelegate
extension ProfileInfoView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        self.pagesControl.currentPage = indexPath.row
    }
}

//MARK: - UICollectionViewDataSource
extension ProfileInfoView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.comments.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ProfileCommentCollectionCell = collectionView.dequeueReusableCell(indexPath: indexPath)
        cell.textLabel?.text = self.comments[indexPath.row]
        
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension ProfileInfoView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return self.collectionView.frame.size 
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}
