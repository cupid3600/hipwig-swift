//
//  MicrophonePermissionsCheck.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

class MicrophonePermissionsCheck: PermissionsCheck, PermissionsCheckDelegate {
    
    let audioSession = AVAudioSession.sharedInstance()
    
    private var completion: CheckPermissionClosure?
    
    override init() {
        super.init()
        self.delegate = self
    }
    
    func check(_ completion: @escaping CheckPermissionClosure) {
        self.completion = completion
        self.defaultAction()
    }
    
    override func checkStatus() {
        let currentStatus = self.status
        
        if AVAudioSession.sharedInstance().isInputAvailable {
            if AVAudioSession.sharedInstance().recordPermission == .granted {
                self.status = .enabled
            } else {
                self.status = .disabled
            }
        } else {
            self.status = .unavailable
        }
        
        if self.status != currentStatus {
            self.updateStatus()
        }
    }
    
    override func defaultAction() {
        if AVAudioSession.sharedInstance().recordPermission == .denied {
            self.openSettings()
        }else{
            AVAudioSession.sharedInstance().requestRecordPermission { result in
                if result {
                    self.status = .enabled
                } else {
                    self.status = .disabled
                }
                
                self.updateStatus()
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
