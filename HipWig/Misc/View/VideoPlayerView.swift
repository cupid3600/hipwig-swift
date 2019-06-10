//
//  VideoPlayerView.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 1/31/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPlayerView: UIView {
    
    private var videoPlayer: AVPlayer?
    private var videoLayer: AVPlayerLayer?
    
    private var playVideoButton: UIButton = {
        let button = UIButton()
        button.adjustsImageWhenHighlighted = false
        button.setImage(UIImage(named: "play_video"), for: .normal)
        
        return button
    }()
    
    var usePlayButton: Bool = true {
        didSet{
            self.playVideoButton.isUserInteractionEnabled = usePlayButton
        }
    }
    
    private var url: URL?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.videoLayer != nil {
            self.videoLayer?.frame = self.bounds
        }
    }
    
    private func onLoad() {
        self.isHidden = true
        self.clipsToBounds = true
        self.layer.cornerRadius = 8.0
        
        self.place(self.playVideoButton)
        self.playVideoButton.addTarget(self, action: #selector(togglePlayButtonState(sender:)), for: .touchUpInside)
        self.playVideoButton.isHidden = true
        
        NotificationCenter.addApplicationResignActiveObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.reset()
        }
    }
    
    func setVideo(_ url: URL) {
        self.url = url
        
        self.isHidden = false
        self.playVideoButton.isHidden = false
        
        let item = AVPlayerItem(url: url)

        self.videoPlayer = AVPlayer(playerItem: item)
        self.videoPlayer?.actionAtItemEnd = .pause
        
        if self.videoLayer != nil {
            self.videoLayer?.removeFromSuperlayer()
        }
        
        self.videoLayer = AVPlayerLayer(player: self.videoPlayer)
        self.videoLayer?.frame = self.bounds
        self.videoLayer?.videoGravity = .resizeAspectFill
        
        self.layer.insertSublayer(self.videoLayer!, at: 0)
        
        NotificationCenter.addItemDidPlayToEndTimeObserver(self.videoPlayer!.currentItem) { [weak self] item in
            guard let `self` = self else { return }
            
            self.playVideoButton.isHidden = false
            self.setVideo(url)
        }
    }
    
    func reset() {
        self.isHidden = true
        self.videoPlayer?.pause()
        self.videoPlayer = nil
        self.videoLayer?.removeFromSuperlayer()
    }
    
    @objc private func togglePlayButtonState(sender: UIButton) {
        self.play()
    }
    
    @objc private func play() {
        self.playVideoButton.isHidden = true
        self.videoPlayer?.play()
    } 
}
