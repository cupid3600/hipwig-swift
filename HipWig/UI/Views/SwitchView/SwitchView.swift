//
//  SwitchView.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 28.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import JTMaterialSwitch
import Device_swift
typealias SwitchViewValueChangeHandler = (SwitchView, Bool) -> Void

class SwitchView: UIView {
    
    private (set) var switchView: JTMaterialSwitch? = {
        let isSmallSize = DeviceType.current == .iPhone5S || DeviceType.current == .iPhone5C || DeviceType.current == .iPhone5
        let size = isSmallSize ? JTMaterialSwitchSizeSmall : JTMaterialSwitchSizeNormal
        let switchView = JTMaterialSwitch(size: size, state: JTMaterialSwitchStateOff)
        
        let onTintColor = selectedColor
        let trackOnTintColor = UIColor(red: 15, green: 244, blue: 195, alpha: 0.4)
        
        let offTintColor = textColor2
        let trackOffTintColor = UIColor(red: 149, green: 157, blue: 173, alpha: 0.4)
        
        switchView?.isBounceEnabled = false
        switchView?.thumbOnTintColor = onTintColor
        switchView?.thumbOffTintColor = offTintColor
        
        switchView?.trackOnTintColor = trackOnTintColor
        switchView?.trackOffTintColor = trackOffTintColor
        
        switchView?.thumbDisabledTintColor = offTintColor
        switchView?.trackDisabledTintColor = trackOffTintColor
        
        switchView?.isRippleEnabled = false
        switchView?.addTarget(self, action: #selector(valueChange(_:)), for: .valueChanged)
        switchView?.translatesAutoresizingMaskIntoConstraints = false
//        switchView?.widthAnchor
        return switchView
    }()
    
    var changeValueHandler: SwitchViewValueChangeHandler = { _, _ in }
    
    var isOn: Bool = false {
        didSet{
            self.switchView?.isOn = isOn
        }
    }
    
    private var handleSelection: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let switchView = self.switchView {
            self.addSubview(switchView)
            
            switchView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
            switchView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.switchView?.frame = self.bounds
    }
    
    func set(isOn: Bool, animated: Bool = false, handleSelection: Bool = true) {
        self.handleSelection = handleSelection
        switchView?.setOn(isOn, animated: animated)
        self.handleSelection = true
    }
    
    @objc private func valueChange(_ sender: JTMaterialSwitch) {
        if handleSelection {
            self.changeValueHandler(self, sender.isOn)
        } 
    }
}
