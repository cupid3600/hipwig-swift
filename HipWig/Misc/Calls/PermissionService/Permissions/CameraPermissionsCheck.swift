//
//  CustomCameraPermission.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

class CameraPermissionsCheck: PermissionsCheck, PermissionsCheckDelegate {
    
    var mediaType = AVMediaType.video
    private var completion: CheckPermissionClosure?
    
    override init() {
        super.init()
        self.delegate = self
    }
    
    override func checkStatus() {
        let currentStatus = self.status
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let authStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
            switch authStatus {
                
            case .authorized:
                self.status = .enabled
            case .denied:
                self.status = .disabled
            case .notDetermined:
                self.status = .disabled
            default:
                self.status = .unavailable
            }
        } else {
            self.status = .unavailable
        }
        
        if self.status != currentStatus {
            self.updateStatus()
        }
    }
    
    func check(_ completion: @escaping CheckPermissionClosure) {
        self.completion = completion
        self.defaultAction()
    }
    
    override func defaultAction() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let authStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
            if authStatus == .denied {
                self.openSettings()
            } else {
                AVCaptureDevice.requestAccess(for: mediaType) { result in
                    if result {
                        self.status = .enabled
                    } else {
                        self.status = .disabled
                    }
                    
                    self.updateStatus()
                }
                
            }
        }
    }
    
    func permissionCheck(_ permissionCheck: PermissionsCheck, didCheckStatus: PermissionsStatus) {
        if let completion = self.completion {
            completion(didCheckStatus)
        }
        
        self.completion = nil
    }
}

