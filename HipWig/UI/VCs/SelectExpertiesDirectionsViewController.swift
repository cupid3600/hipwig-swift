//
//  SelectExpertiesDirectionsViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 1/31/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Kingfisher
import Alamofire

@objc protocol SelectExpertiesDirectionsViewControllerDelegate: class {
    
    func didSelectDirection(with directions: [ExpertSkill])
    @objc optional func didSelectPublishProfile()
    @objc optional func didChangeLocation(with location: String?)
}

class SelectExpertiesDirectionsViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var publishProfileButton: UIButton!
    @IBOutlet private weak var selectedDirectionsLabel: UILabel!
    @IBOutlet private weak var enableLocationLabel: UILabel!
    @IBOutlet private weak var disabledLocationDescriptionLabel: UILabel!
    @IBOutlet private weak var directionsCollectionView: UICollectionView!
    @IBOutlet private weak var enableLocationSwitchView: SwitchView!
    @IBOutlet private weak var updateLocationActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var locadDirectionsActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var collectionBottomConstraintToSafeArea: NSLayoutConstraint!
    @IBOutlet private weak var collectionBottomConstraint: NSLayoutConstraint!
    
    //MARK: - Interface -
    var user: InternalExpert? {
        didSet {
            self.selectedSkills = user?.directions ?? []
        }
    }
    
    var usePublishProfileButton: Bool = true
    private (set) var isLoading: Bool = false {
        didSet {
            if isLoading {
                self.locadDirectionsActivityIndicator.startAnimating()
            } else {
                self.locadDirectionsActivityIndicator.stopAnimating()
            }
        }
    }
    weak var delegate: SelectExpertiesDirectionsViewControllerDelegate?
    
    //MARK: - Properties -
    private var skills: [ExpertSkill] = []
    private var selectedSkills: [ExpertSkill] = [] {
        didSet {
            self.user?.directions = self.selectedSkills
            self.updateDirectionsLabel(with: self.selectedSkills.count)
        }
    }
    private let cellInset: CGFloat = 30.0
    private let cellCountPerRow: CGFloat = 3
    private var pagination: Pagination = .default
    private let locationService: LocationService = LocationServiceImplementation()
    private let api = RequestsManager.manager
    
    //MARK: - Life Cicle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.locationService.stopUpdatingLocation()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Actions -
    @IBAction func publishProfileDidSelect(_ sender: UIButton) {
        self.delegate?.didSelectPublishProfile?()
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(publishProfile: self.publishProfileButton)
        self.setup(selectedDirectionsLabel: self.selectedDirectionsLabel)
        self.setup(collectionView: self.directionsCollectionView)
        self.setup(enableLocation: self.enableLocationSwitchView)
        self.setup(locationDeniedDescription: self.disabledLocationDescriptionLabel)

        self.updateDirectionsLabel(with: self.selectedSkills.count)
        self.enableLocationSwitchView.set(isOn: self.user?.enableLocation ?? false, handleSelection: false)
        self.updatePublishButton(with: self.user?.readyToSave ?? false)
        self.updateLocationActivityIndicator.isHidden = true
        
        if let user = self.user {
            if user.enableLocation {
                if user.location == nil || user.location!.isEmpty {
                    self.locationService.startUpdatingLocation()
                    self.fetchUserLocation()
                }
            }
        }

        self.collectionBottomConstraint.isActive = self.usePublishProfileButton
        self.collectionBottomConstraintToSafeArea.isActive = !self.usePublishProfileButton
        
        self.fetchDirectionList()

        self.locationService.statusChanged { [weak self] status in
            guard let `self` = self else { return }
            
            var allowInteraction = false
            if status == .denied {
                self.updateLocationActivityIndicator.stopAnimating()
                self.enableLocationSwitchView.set(isOn: false, animated: false, handleSelection: false)
            } else {
                allowInteraction = true
            }
            
            self.enableLocationSwitchView.isUserInteractionEnabled = allowInteraction
            self.disabledLocationDescriptionLabel.isHidden = allowInteraction
        }
        
        self.view.adjustConstraints()
        
        self.publishProfileButton.titleLabel?.font = self.publishProfileButton.titleLabel?.font?.adjusted
        self.selectedDirectionsLabel.font = self.selectedDirectionsLabel.font.adjusted
        self.enableLocationLabel.font = self.enableLocationLabel.font.adjusted
        self.disabledLocationDescriptionLabel.font = self.disabledLocationDescriptionLabel.font.adjusted
    }
    
    private func fetchDirectionList() {
        self.isLoading = true
        let prevSelfValue = self
        self.api.fetchExpertSkillList(self.pagination) { [weak self] result in
            guard let `self` = self else { return }
            if prevSelfValue !== self {
                return
            }
            
            self.isLoading = false
            
            switch result {
            case .success(let data):
                self.skills = data.rows
                self.directionsCollectionView.reloadData()

                // prefetch selected images
                let tempImage = UIImageView()
                for skill in self.skills {
                    tempImage.setImage(skill.selectedImage)
                }

            case .failure(let error):
                logger.log(error)
            } 
        }
    }
    
    private func fetchUserLocation() {
        self.updateLocationActivityIndicator.startAnimating()
        self.locationService.fetchLocation { location in
            self.enableLocationSwitchView.set(isOn: true, animated: false, handleSelection: false)
            self.user?.location = location
            self.updateLocationActivityIndicator.stopAnimating()
            self.delegate?.didChangeLocation?(with: location)
        }
    }
    
    private func updateDirectionsLabel(with count: Int) {
        if self.selectedDirectionsLabel != nil {
            if count == 0 {
                self.selectedDirectionsLabel.text = "become_an_expert.expertis.please_select_directions".localized
            } else {
                self.selectedDirectionsLabel.text = "become_an_expert.expertis.selected_directions".localize(values: "\(count)", "\(ExpertSkill.maxSkills)")
            } 
        }
    }
    
    private func setup(enableLocationLabel label: UILabel) {
        label.textColor = .white
        label.font = Font.regular.of(size: 16)
    }
    
    private func setup(directionsLabel label: UILabel) {
        self.selectedDirectionsLabel.font = Font.regular.of(size: 16)
    }
    
    private func setup(enableLocation swithView: SwitchView) {
        swithView.changeValueHandler = { [weak self] _, value in
            guard let `self` = self else { return }
            
            self.user?.enableLocation = value
            
            if value {
                self.fetchUserLocation()
            } else {
                self.locationService.stopUpdatingLocation()
                self.delegate?.didChangeLocation?(with: nil)
            }
        }
    }
    
    private func updatePublishButton(with canPublish: Bool) {
        self.publishProfileButton.isUserInteractionEnabled = canPublish
        
        if canPublish {
            self.publishProfileButton.backgroundColor = selectedColor
        } else {
            self.publishProfileButton.backgroundColor = disabledColor
        }
        
        self.publishProfileButton.isHidden = !self.usePublishProfileButton 
    }
    
    private func setup(publishProfile button: UIButton) {
        button.titleLabel?.font = Font.regular.of(size: 16)
        button.layer.cornerRadius = 8.adjusted
        button.clipsToBounds = true
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .center
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: -14.0, bottom: 0.0, right: 0.0)
        button.tintColor = .white
        
        button.setTitleColor(kTextColor, for: .normal)
        button.setTitle("become_an_expert.expertis.publish_profile_title".localized, for: .normal)
        button.backgroundColor = selectedColor
    }
    
    private func setup(collectionView: UICollectionView) {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.registerNib(with: ExpertDirectionCell.self)
        collectionView.allowsMultipleSelection = false
    }
    
    private func setup(selectedDirectionsLabel label: UILabel) {
        label.font = Font.regular.of(size: 16)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
    }

    private func setup(locationDeniedDescription label: UILabel) {
        label.font = Font.regular.of(size: 14)
        label.text = "become_an_expert.expertis.denied_location_description".localized
        label.isHidden = true
    }
}

//MARK: - UICollectionViewDelegate
extension SelectExpertiesDirectionsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        let direction = self.skills[indexPath.row]
        
        if let index = self.selectedSkills.index(where: { $0.id == direction.id }) {
            self.selectedSkills.remove(at: index)
        } else {
            if self.selectedSkills.count < InternalExpert.maxDirectionCount {
                self.selectedSkills.append(direction)
            } else {
                collectionView.deselectItem(at: indexPath, animated: false)
                return
            }
        }
        
        collectionView.reloadItems(at: [indexPath])
        
        self.delegate?.didSelectDirection(with: self.selectedSkills)
        self.updatePublishButton(with: self.user?.readyToSave ?? false)
    }
}
    
//MARK: - UICollectionViewDelegateFlowLayout
extension SelectExpertiesDirectionsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return self.cellInset / 2.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.width
        let cellWidth = (width - self.cellInset) / self.cellCountPerRow
        return CGSize(width: cellWidth, height: cellWidth)

    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}

//MARK: - UICollectionViewDataSource
extension SelectExpertiesDirectionsViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: ExpertDirectionCell = collectionView.dequeueReusableCell(indexPath: indexPath)
        
        let skill = self.skills[indexPath.row]
        cell.skill = skill
        cell.isSelected = selectedSkills.contains(where: { $0.id == skill.id })
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.skills.count
    }
}

