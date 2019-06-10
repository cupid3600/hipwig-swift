//
//  ExpertOptionsViewController.swift
//  HipWig
//
//  Created by Alexey on 1/15/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ExpertOptionsViewController: UIViewController, BigOptionSegmentDelegate {

    @IBOutlet private var purposeSegment: BigOptionSegment!

    @IBOutlet private var sexTitleLabel: UILabel!
    @IBOutlet private var sexSegment: BigOptionSegment!

    @IBOutlet private var locationTitleLabel: UILabel!
    @IBOutlet private var locationSegment: BigOptionSegment!

    private var isSexBlockShowed = false
    private var isLocationBlockShowed = false

    private var purposeValue: String?
    private var sexValue: String?
    private var locationValue: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.sexTitleLabel.alpha = 0.0
        self.sexSegment.alpha = 0.0
        self.locationTitleLabel.alpha = 0.0
        self.locationSegment.alpha = 0.0

        self.purposeSegment.type = .purpose
        self.purposeSegment.titles = ["Need an advice", "Someone to talk"]
        self.purposeSegment.values = ["tip", "talk"]
        self.purposeSegment.normalIcons = ["advice_icon", "someone_icon"]
        self.purposeSegment.selectedIcons = ["advice_selected_icon", "someone_selected_icon"]
        self.purposeSegment.delegate = self
        self.purposeSegment.applyDefaultState()

        self.sexSegment.type = .sex
        self.sexSegment.titles = ["Woman", "Man"]
        self.sexSegment.values = ["female", "male"]
        self.sexSegment.normalIcons = ["woman_icon", "man_icon"]
        self.sexSegment.selectedIcons = ["woman_selected_icon", "man_selected_icon"]
        self.sexSegment.delegate = self
        self.sexSegment.applyDefaultState()

        self.locationSegment.type = .location
        self.locationSegment.titles = ["Local", "World wide"]
        self.locationSegment.values = ["local", "world"]
        self.locationSegment.normalIcons = ["local_icon", "world_wide_icon"]
        self.locationSegment.selectedIcons = ["local_selected_icon", "world_wide_selected_icon"]
        self.locationSegment.delegate = self
        self.locationSegment.applyDefaultState()
    }

    func onSegmentAction(type: OptionSegmentType, value: String) {
        // get values
        switch type {
        case .purpose:
            self.purposeValue = value
        case .sex:
            self.sexValue = value
        case .location:
            self.locationValue = value
        default:
            self.purposeValue = nil
            self.sexValue = nil
            self.locationValue = nil
        }

        if self.purposeValue != nil && !self.isSexBlockShowed {
            UIView.animate(withDuration: 0.35) {
                self.sexTitleLabel.alpha = 1.0
                self.sexSegment.alpha = 1.0
            }
            self.isSexBlockShowed = true
            return
        }

        if self.sexValue != nil && !self.isLocationBlockShowed {
            UIView.animate(withDuration: 0.35) {
                self.locationTitleLabel.alpha = 1.0
                self.locationSegment.alpha = 1.0
            }
            self.isLocationBlockShowed = true
            return
        }

        if let _ = self.purposeValue, let _ = self.sexValue, let _ = self.locationValue  {
//            self.performSegue(withIdentifier: kPurposeToExpertsSegueID, sender: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}
