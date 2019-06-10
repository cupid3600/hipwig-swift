//
//  PauseCallViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/25/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

private let hasDisplayedPauseViewKey = "hasDisplayedPauseViewKey"

class PauseCallViewController: BaseViewController {

    
    //MARK: - Public -
    public var closeButtonFrame: CGRect = .zero
    public var closeSelectedClosure: () -> Void = {}
    
    //MARK: - Outlets -
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var closeButtonTopConstraint: NSLayoutConstraint!
    
    public static var hasDisplayedPauseView: Bool {
        get {
            return UserDefaults.standard.value(forKeyPath: "hasDisplayedPauseViewKey") != nil
        }
    }
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
        
        UserDefaults.standard.set(true, forKey: hasDisplayedPauseViewKey)
        UserDefaults.standard.synchronize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.backgroundColor = .clear
        self.showAnimate(with: self.containerView)
        
        self.closeButtonTopConstraint.constant = self.closeButtonFrame.minY
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.removeObject(forKey: hasDisplayedPauseViewKey)
        UserDefaults.standard.synchronize()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Public -
    func hide(animated: Bool) {
        if animated {
            self.removeAnimate(with: self.containerView)
        } else {
            self.dismiss(animated: false)
        }
    }
    
    //MARK: - Actions -
    @IBAction private func closeSelected(_ sender: UIButton) {
        self.closeSelectedClosure()
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(containerView: self.containerView)
        
        self.titleLabel.font = self.titleLabel.font.adjusted
        self.detailsLabel.font = self.detailsLabel.font.adjusted
        self.view.adjustConstraints() 
    }
    
    private func setup(containerView view: UIView) {
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
    }
}
