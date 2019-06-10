//
//  ExpertListCell.swift
//  HipWig
//
//  Created by Alexey on 1/18/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit 
import ASPVideoPlayer
import Alamofire
import Kingfisher

class ExpertListCell: UICollectionViewCell, VideoCell {

    public var user: User?
    public var reuseAction: () -> Void = { }
    public var stopPlayingAction: () -> Void = { }
    
    @IBOutlet private var expertNameLabel: UILabel!
    @IBOutlet private var profileImageView: UIImageView!
    @IBOutlet private var onlineView: UIView!
    @IBOutlet private var videoContainer: UIView!
    @IBOutlet private var videoPlayer: ASPVideoPlayerView?
  
    private let onlineBorderColor = UIColor(displayP3Red: 57.0/255.0, green: 61.0/255.0, blue: 83.0/255.0, alpha: 1.0)
    private let selectedColor = UIColor(displayP3Red: 106.0/255.0, green: 239.0/255.0, blue: 207.0/255.0, alpha: 1.0)

    private var videoStopped: Bool = true {
        didSet {
            DispatchQueue.main.async {
                self.videoPlayer?.isHidden = self.videoStopped
            }
        }
    }

    private var downloadVideoRequest: DownloadRequest?
    private var downloadImageTask: DownloadTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.videoContainer.layer.cornerRadius = 12.adjusted
        self.videoContainer.layer.shouldRasterize = true
        self.videoContainer.layer.rasterizationScale = UIScreen.main.scale
        self.videoContainer.layer.masksToBounds = true
        self.videoContainer.layer.borderColor = self.selectedColor.cgColor
        self.videoStopped = true
        
        self.onlineView.layer.cornerRadius = 6.adjusted
        self.onlineView.layer.shouldRasterize = true
        self.onlineView.layer.rasterizationScale = UIScreen.main.scale
        self.onlineView.layer.masksToBounds = true
        self.onlineView.layer.borderWidth = 2.adjusted
        self.onlineView.layer.borderColor = self.onlineBorderColor.cgColor
        
        self.videoPlayer?.volume = 0.0
        self.videoPlayer?.startPlayingWhenReady = true
        self.videoPlayer?.shouldLoop = true
        
        self.videoPlayer?.finishedVideo = { [weak self] in
            self?.stopPlayingAction()
        }
        
        self.adjustConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.downloadImageTask?.cancel()
            self?.downloadImageTask = nil
            
            self?.downloadVideoRequest?.cancel()
            self?.downloadVideoRequest = nil
            self?.videoPlayer?.stopVideo()
            
            self?.reuseAction()
        }
    }

    public func setup(user: User) {
        self.user = user
        self.expertNameLabel.text = user.expert?.name
        self.videoContainer.layer.borderWidth = 0.0
        self.onlineView.isHidden = !(user.expert?.available ?? false)
        
        self.videoStopped = true
        self.downloadImageTask = self.profileImageView.setImage(user.profileImage, placeholder: "expert_placeholder")
    }
    
    func playVideo() {
        self.videoStopped = true
        
        if let profileVideo = self.user?.expert?.profileVideo {
            self.downloadVideoRequest = VideosProvider.provider.videoFile(videoURL: profileVideo) { videoUrl in
                if let url = videoUrl {
                    changeAudioSessionToDuckOther()
                    self.videoPlayer?.videoURL = url
                    self.animateVideoView()
                }
                
                self.videoStopped = videoUrl == nil
            }
        }
    }
    
    func stopVideo() {
        DispatchQueue.main.async {
            self.videoStopped = true
            self.videoPlayer?.stopVideo()
        } 
    }
    
    private func animateVideoView() {
        DispatchQueue.main.async {
            self.videoPlayer?.alpha = 0.0
            
            UIView.animate(withDuration: 0.5) {
                self.videoPlayer?.alpha = 1.0
            }
        }
    }
    
    
}

func changeAudioSessionToDuckOther() {
    do {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
        try audioSession.setActive(true)
    } catch {
        
    }
}
