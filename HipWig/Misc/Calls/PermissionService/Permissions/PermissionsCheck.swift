//
//  PermissionsCheck.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

public enum PermissionsStatus: Int {
    case disabled
    case enabled
    case checking
    case unavailable
    case denied
}

protocol PermissionsCheckDelegate: class {
    func permissionCheck(_ permissionCheck: PermissionsCheck, didCheckStatus: PermissionsStatus);
}

typealias CheckPermissionClosure = (_ status: PermissionsStatus) -> Void

class PermissionsCheck: NSObject {
    
    weak var delegate: PermissionsCheckDelegate?
    var status: PermissionsStatus = PermissionsStatus.checking
    var canBeDisabled = false
    
    func checkStatus() {
        fatalError("checkStatus has not been implemented")
    }
    
    func defaultAction() {
        fatalError("defaultAction has not been implemented")
    }
    
    func updateStatus() {
        if let d = self.delegate {
            DispatchQueue.main.async{
                d.permissionCheck(self, didCheckStatus: self.status)
            }
        }
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}
