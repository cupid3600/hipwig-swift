//
//  RecordVideoViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 1/30/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol RecordVideoViewControllerDelegate: class {
    func controller(_ controller: RecordVideoViewController, didFinishWithVideoURL videoURL: URL)
}

class RecordVideoViewController: BaseViewController {

    //MARK: - Outlets -
    @IBOutlet private weak var recordVideoProgressBarView: ProgressBar!
    @IBOutlet private weak var pulseButton: PulseButton!
    @IBOutlet private weak var previewView: UIView!
    @IBOutlet private weak var recordTimeLabel: UILabel!
    @IBOutlet private weak var helpRecordLabel: UILabel!
    @IBOutlet private weak var keepVideoButton: UIButton!
    @IBOutlet private weak var saveVideoCheckMarkImageView: UIImageView!
    @IBOutlet private weak var videoPlayerView: VideoPlayerView!
    
    //MARK: - Properties -
    private let captureProvider = CaptureVideoProvider()
    private let progressLowerColor = UIColor(displayP3Red: 240.0/255.0, green: 117.0/255.0, blue: 169.0/255.0, alpha: 1.0)
    private let progressUpperColor = UIColor(displayP3Red: 106/255.0, green: 239/255.0, blue: 207/255.0, alpha: 1.0)
    private var allowVideoRecord: Bool = true {
        didSet {
            self.pulseButton.isUserInteractionEnabled = allowVideoRecord
        }
    }
    private var videoCouldBeSaved = false {
        didSet {
            if self.startRecording {
                self.helpRecordLabel.isHidden = true
            } else {
                self.helpRecordLabel.isHidden = videoCouldBeSaved
            }
            
            self.keepVideoButton.isHidden = !videoCouldBeSaved
        }
    }
    private var startRecording = false
    private var canSaveVideoPreviousState: Bool? = nil
    
    //MARK: - Interface -
    var videoURL: URL?
    var defaultVideoURL: URL?
    weak var delegate: RecordVideoViewControllerDelegate?
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.captureProvider.resumeSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.captureProvider.stopSession()
        self.videoPlayerView.reset()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Actions -
    @IBAction func keepVideoDidSelect(_ sender: UIButton) {
        if let url = self.videoURL {
            self.delegate?.controller(self, didFinishWithVideoURL: url)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(pulseButton: self.pulseButton)
        self.setup(recordVideoProgressBarView: self.recordVideoProgressBarView)
        
        self.captureProvider.setup()
        
        self.setup(captureProvider: self.captureProvider)
        self.setup(keepVideoButton: self.keepVideoButton)
        
        self.videoCouldBeSaved = false
        self.saveVideoCheckMarkImageView.isHidden = true  
        self.view.adjustConstraints()
        
        if let url = self.videoURL {
            self.defaultVideoURL = url
            self.updateView(with: url)
        }
        
        
        NotificationCenter.addApplicationDidEnterBackgroundObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.canSaveVideoPreviousState = self.videoCouldBeSaved
            self.pulseButton.reset()
            self.releaseButton()
        }
        
        NotificationCenter.addApplicationWillEnterForegroundObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.canSaveVideoPreviousState = nil
            
            if let url = self.videoURL {
                self.videoPlayerView.setVideo(url)
            } else if let url = self.defaultVideoURL {
                self.videoPlayerView.setVideo(url)
            } 
        }
    }
    
    private func setup(captureProvider: CaptureVideoProvider) {
        self.captureProvider.addPreviewLayerToView(view: self.previewView)
        self.captureProvider.delegate = self
    }
    
    private func setup(keepVideoButton button: UIButton) {
        button.titleLabel?.font = Font.regular.of(size: 16)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(kTextColor, for: .normal)
        button.setTitle("become_an_expert.record_video.keep_button_title".localized, for: .normal)
        button.backgroundColor = selectedColor
    }
    
    private func setup(recordVideoProgressBarView progressBar: ProgressBar) {
        progressBar.upperBound = CGFloat(self.captureProvider.maxRecordTimeInterval)
        progressBar.trackPadding = 0.0
        progressBar.barColorForValue = { [weak self] value in
            guard let `self` = self else { return .clear }
            
            self.videoCouldBeSaved = Double(value) >= self.captureProvider.minRecordTime
            self.saveVideoCheckMarkImageView.isHidden = !self.videoCouldBeSaved

            return self.videoCouldBeSaved ? self.progressUpperColor : self.progressLowerColor
        }
    }
    
    private func setup(pulseButton: PulseButton) {
        pulseButton.delegate = self
    } 
}

//MARK: - PulseButtonDelegate
extension RecordVideoViewController: PulseButtonDelegate {
    
    func selectButton() {
        if !self.captureProvider.isVideoRecordingAllowed {
            self.captureProvider.askVideoRecPermissions { [weak self] isAllowed in
                guard let `self` = self else { return }
                
                if isAllowed {
                    self.startVideoRecording()
                } else {
                    self.pulseButton.reset()
                    ModalStoryboard.showVideoPermissionDeniedAlert()
                }
            }
        } else {
            if self.allowVideoRecord {
                self.startVideoRecording()
            }
        }
    }
    
    func releaseButton() {
        self.startRecording = false
        self.allowVideoRecord = false
        
        self.captureProvider.stopRecording { [weak self] in
            guard let `self` = self else { return }

            self.allowVideoRecord = true
        }
    }

    private func startVideoRecording() {
        self.startRecording = true
        self.videoPlayerView.reset()
        self.captureProvider.startRecording()
    }
}

//MARK: - CaptureVideoProviderDelegate
extension RecordVideoViewController: CaptureVideoProviderDelegate {
    
    private func resetProgress() {
        self.videoCouldBeSaved = false
        self.recordVideoProgressBarView.progressValue = 0
        self.recordTimeLabel.text?.removeAll()
    }
    
    func provider(_ provider: CaptureVideoProvider, recordTimeDidChange recordTime: Double) {
        self.recordVideoProgressBarView.progressValue = CGFloat(recordTime)
        self.recordTimeLabel.text = "become_an_expert.record_video.record_time".localize(value: "\(Int(recordTime))")

        if Int(recordTime) >= Int(self.captureProvider.maxRecordTimeInterval) {
            self.releaseButton()
            self.pulseButton.reset()
        }
    }
    
    func provider(_ provider: CaptureVideoProvider, didFinishWithVideoURL videoURL: URL) {
        self.updateView(with: videoURL)
    }
    
    private func updateView(with videoURL: URL) {
        self.startRecording = false
        self.videoCouldBeSaved = true
        
        self.videoURL = videoURL
        self.videoPlayerView.setVideo(videoURL)
    }
    
    func provider(_ provider: CaptureVideoProvider, didFinishWithError error: CaptureVideoProviderError) {
        if let value = self.canSaveVideoPreviousState {
            if !value {
                self.resetProgress()
            }
        } else if self.canSaveVideoPreviousState == nil {
            self.resetProgress()
        }

        if let url = self.videoURL {
            self.updateView(with: url)
        } else if let url = self.defaultVideoURL {
            self.updateView(with: url)
        }
    }
} 
