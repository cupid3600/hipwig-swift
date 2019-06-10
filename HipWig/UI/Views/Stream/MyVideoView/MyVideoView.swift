//
//  MyVideoView.swift
//  HipWig
//
//  Created by Alexey on 2/4/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol MyVideoViewDelegate: class {
    func view(_ view: MyVideoView, changePublishVideState state: Bool)
    func onMyCameraPositionToggle()
}

class MyVideoView: UIView {

    //MARK: - Outlets -
    @IBOutlet public var videoToggleBtn: UIButton!
    @IBOutlet public var cameraToggleBtn: UIButton!
    @IBOutlet private var streamView: UIView!
    @IBOutlet private var viewHeight: NSLayoutConstraint!

    //MARK: - Properties -
    private var videoView: UIView?

    //MARK: - Interface -
    public weak var delegate: MyVideoViewDelegate?
    public func setupMyStream(view: UIView) {
        view.frame = CGRect(x: 0, y: 0, width: 90.0.adjusted, height: 96.0.adjusted)
        self.streamView.addSubview(view)

        self.videoView = view
    }
    
    public func setVideo(isOn: Bool, animated: Bool = true) {
        if isOn {
            self.videoOnMode()
        } else {
            self.videoOffMode()
        }
        
        self.videoToggleBtn.isSelected = isOn
    }
    
    public func clean() {
        self.videoView?.removeFromSuperview()
        self.videoView = nil
    }

    //MARK: - Life Cycle -
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        if let viewFromXIB = MyVideoView.fromXib(owner: self) {
            self.place(viewFromXIB)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.layer.cornerRadius = 12.0.adjusted
        self.layer.masksToBounds = true

        self.videoToggleBtn.titleLabel?.font = self.videoToggleBtn.titleLabel?.font?.adjusted
        self.videoToggleBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        self.videoToggleBtn.setTitle("stream.camera_is_off".localized, for: .normal)
        self.videoToggleBtn.setTitle("stream.camera_is_on".localized, for: .selected)
    }
    
    //MARK: - Actions -
    @IBAction private func cameraToggleDidPressed() {
        self.delegate?.onMyCameraPositionToggle()
    }

    @IBAction private func videoToggleDidPressed(sender: UIButton) {
        sender.isSelected.toggle()
        
        self.setVideo(isOn: sender.isSelected)
        self.delegate?.view(self, changePublishVideState: sender.isSelected)
    }

    //MARK: - Private -
    private func videoOffMode() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.viewHeight.constant = 0.0

            self?.superview?.layoutIfNeeded()
            self?.videoView?.alpha = 0.0
        }
    }

    private func videoOnMode() {
        UIView.animate(withDuration: 0.2) {
            self.viewHeight.constant = 96.0.adjusted
            
            self.superview?.layoutIfNeeded()
            self.videoView?.alpha = 1.0
        }
    }
}
