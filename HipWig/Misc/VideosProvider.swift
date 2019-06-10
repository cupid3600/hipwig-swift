//
//  VideosProvider.swift
//  HipWig
//
//  Created by Alexey on 1/18/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Alamofire
import AVFoundation

class VideosProvider {
    
    static public var provider = VideosProvider()

    private init() {
        
    }

    private let destination: DownloadRequest.DownloadFileDestination = { _, resp in
        let tempDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("videos")!
        let fileURL = tempDirURL.appendingPathComponent(resp.url!.lastPathComponent)
        
        return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
    }
    
    private func downloadFile(videoURL: String?, completion: @escaping (URL?) -> Void) -> DownloadRequest? {
        guard let profileVideo = videoURL else {
            return nil
        }
        
        return Alamofire.download(profileVideo, to: self.destination).validate().downloadProgress { _ in
            
            }.response { response in
                
            if let _ = response.error {
                completion(nil)
            } else {
                completion(response.destinationURL)
            }
        }
    }
    
    @discardableResult
    public func videoFile(videoURL: String?, completion: @escaping (URL?) -> Void) -> DownloadRequest? {
        guard let profileVideo = videoURL else {
            return nil
        }
        
        let tempDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("videos")!
        let fileName = URL(string: profileVideo)!.lastPathComponent
        let fileURL = tempDirURL.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            completion(fileURL)
            return nil
        } else {
            return self.downloadFile(videoURL: profileVideo, completion: completion)
        }
    }
    
    public func hasVideoFile(with profileVideoURL: String) -> (localVideoExist: Bool, localVideoURL: URL) {
        
        let tempDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("videos")!
        let fileName = URL(string: profileVideoURL)!.lastPathComponent
        let fileURL = tempDirURL.appendingPathComponent(fileName)
        
        return (localVideoExist: FileManager.default.fileExists(atPath: fileURL.path), localVideoURL: fileURL)
    } 
}
