//
//  CaptureVideoProvider.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 1/30/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

enum CaptureVideoProviderError: Error {
    case videoToSmall
    case unknown(String)
    case stillRecording
}

protocol CaptureVideoProviderDelegate: class {
    func provider(_ provider: CaptureVideoProvider, recordTimeDidChange recordTime: Double)
    func provider(_ provider: CaptureVideoProvider, didFinishWithVideoURL videoURL: URL)
    func provider(_ provider: CaptureVideoProvider, didFinishWithError error: CaptureVideoProviderError)
}

class CaptureVideoProvider: NSObject {

    private var cameraManager: CameraManager?
    private var timer: Timer?
    private var recordTimeInterval: Double = 0
    private let timerStep: Double = 1.0
    private var canStartRecording = true
    private let workQueue = DispatchQueue(label: "com.CaptureVideoProvider.captureQueue", qos: .userInteractive)
    
    let maxRecordTimeInterval: Double = 60.0
    let minRecordTime: Double = 15.0
    
    weak var delegate: CaptureVideoProviderDelegate?
    
    func setup() {
        self.cameraManager = CameraManager()
        
        self.cameraManager?.showAccessPermissionPopupAutomatically = true
        self.cameraManager?.showErrorsToUsers = true
        self.cameraManager?.cameraDevice = .front
        self.cameraManager?.cameraOutputQuality = .medium
        
        self.cameraManager?.showErrorBlock = { [weak self] _, message in
            guard let `self` = self else { return }
            
            DispatchQueue.main.async {
                self.delegate?.provider(self, didFinishWithError: .unknown(message))
            }
        }
        
        self.cameraManager?.createSessionFailureBlock = { [weak self] in
            guard let `self` = self else { return }
            
            self.stopTimer()
        }
    }
    
    func addPreviewLayerToView(view: UIView) {
        self.cameraManager?.addPreviewLayerToView(view) 
    } 
    
    func resumeSession() {
        self.workQueue.async { [weak self] in
            guard let `self` = self else { return }
            
            if self.cameraManager?.hasRunningSession ?? false {
                self.cameraManager?.resumeCaptureSession()
            }
        }
    }
    
    func stopSession() {
        self.stopTimer()
        self.canStartRecording = true
        
        self.workQueue.async { [weak self] in
            guard let `self` = self else { return }
            
            self.cameraManager?.stopCaptureSession() 
        }
    }
    
    func startRecording() {
        self.stopTimer()
        if canStartRecording {
            self.canStartRecording = false
            self.delegate?.provider(self, recordTimeDidChange: self.recordTimeInterval)
            
            self.workQueue.async {
                self.cameraManager?.startRecordingVideo()
                DispatchQueue.main.async {
                    self.timer = Timer.scheduledTimer(withTimeInterval: self.timerStep, repeats: true) { [weak self] timer in
                        guard let `self` = self else { return }
                        
                        self.recordTimeInterval += self.timerStep
                        
                        self.delegate?.provider(self, recordTimeDidChange: self.recordTimeInterval)
                    }
                }
            }
        } else {
            self.delegate?.provider(self, didFinishWithError: .stillRecording)
        }
    }
    
    private func stopTimer() {
        self.recordTimeInterval = 0
        self.timer?.invalidate()
        self.timer = nil
        self.canStartRecording  = true
    }
    
    func stopRecording(completion: @escaping () -> Void) {
        self.workQueue.async {
            self.cameraManager?.stopVideoRecording { [weak self] videoURL, error in
                guard let `self` = self else { return }
                
                DispatchQueue.main.async {
                    completion()
                    
                    let recordTime = self.recordTimeInterval
                    self.stopTimer()
                    
                    if recordTime < self.minRecordTime {
                        self.delegate?.provider(self, didFinishWithError: .videoToSmall)
                    } else {
                        if let url = videoURL {
                            self.delegate?.provider(self, didFinishWithVideoURL: url)
                        } else {
                            let errorValue = error?.localizedDescription ?? "Unknown error"
                            self.delegate?.provider(self, didFinishWithError: .unknown(errorValue))
                        }
                    }
                }
            }
        }
    }

    var isVideoRecordingAllowed: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    func askVideoRecPermissions(_ completion: @escaping (Bool) -> Void) {
        self.cameraManager?.askUserForCameraPermission(completion)
    }
}
