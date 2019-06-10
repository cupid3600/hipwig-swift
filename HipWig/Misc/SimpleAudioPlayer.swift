//
//  LoopingAudioPlayer.swift
//  HipWig
//
//  Created by Alexey on 2/5/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Foundation
import AVFoundation

class LoopingAudioPlayer {
    
    private let session: AVAudioSession = AVAudioSession.sharedInstance()
    private var player: AVAudioPlayer?
    
    deinit {
        self.destroy()
        print("\(#file)" + "\(#function)")
    }
    
    func playCurrent(_ category: AVAudioSession.Category? = nil) {
        guard let player = self.player else {
            return
        }
        
        if let category = category {
            do {
                try AVAudioSession.sharedInstance().setCategory(category, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                
            }
        }
        
        player.play()
    }
    

    public func play(name: String, ext: String, volume: Float = 1.0, category: AVAudioSession.Category = .playback, mode: AVAudioSession.Mode = .default) {
        self.destroy()
        
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(category, mode: mode)
            try AVAudioSession.sharedInstance().setActive(true)

            self.player = try AVAudioPlayer(contentsOf: url)
            
            guard let player = self.player else {
                return
            }
            
            player.volume = volume
            player.numberOfLoops = -1
            
            player.play()
            
            NotificationCenter.addAVInteraptionObserver { [weak self] interaption in
                guard let `self` = self else {
                    return
                }
                guard let interaption = interaption else {
                    return
                }
                
                do {
                    if interaption.type == .began {
                        player.pause()
                        
                        try self.session.setCategory(.ambient, mode: .default)
                        
                    } else if interaption.type == .ended {
                        
                        try self.session.setCategory(.playback, mode: .default)
                        
                        if interaption.options == .shouldResume {
                            player.play()
                        }
                    }
                } catch {
                    
                }
            }
        } catch {
            logger.log(error)
        }
    }

    func speaker(isOn on: Bool) {
        
        let port: AVAudioSession.PortOverride = on ? .speaker : .none
        
        do {
            try self.session.setCategory(.playAndRecord, mode: .default)
            try self.session.overrideOutputAudioPort(port)
            try self.session.setActive(true)
        } catch {
            
        }
    }
    
    public func stop() {
        guard let player = self.player else {
            return
        }

        player.stop()
    }
    
    public func destroy() {
        self.stop()
        self.player = nil
    }
}
