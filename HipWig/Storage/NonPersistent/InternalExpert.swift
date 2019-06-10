//
//  InternalExpert.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

typealias DisplayedDirection = String

class InternalExpert: NSObject {
    
    var userImage: String?
    var video: String?
    var directions: [ExpertSkill] = []
    var enableLocation: Bool = false
    var videoWasRecorded: Bool = false
    var payPalEmail: String?
    var location: String?
    var available: Bool = false
    var publicProfile: Bool = false
    var updatingPhoto: UIImage?

    static let maxDirectionCount = 3
    
    override init() {
        super.init()
    }
    
    private static let defaultVideoURL = NSURL.fileURL(withPath: Bundle.main.path(forResource: "intro", ofType: "mov")!)
    
    init(user: User) {
        super.init()
        
        self.userImage = user.profileImage
        self.payPalEmail = user.expert?.paypalAccount
        self.video = user.expert?.profileVideo
        self.directions = user.expert?.skills ?? []
        self.location = user.expert?.location
        self.enableLocation = self.location != nil && !self.location!.isEmpty
        self.available = user.expert?.available ?? false
        self.publicProfile = user.expert?.publicProfile ?? false
    }
    
    func reset() {
        self.userImage = nil
        self.video = nil
        self.directions.removeAll()
        self.enableLocation = false
        self.payPalEmail = nil
    }
    
    var readyToSave: Bool {
        return self.imagesReadyToSave && directionsReadyToSave && emailReadyToSave
    }
    
    var directionsReadyToSave: Bool {
        return directions.count == InternalExpert.maxDirectionCount
    }
    
    var emailReadyToSave: Bool {
        return payPalEmail != nil && payPalEmail!.isValidAsEmail
    }
    
    var imagesReadyToSave: Bool {
        if self.updatingPhoto == nil {
            return self.userImage != nil && self.video != nil
        } else {
            return self.updatingPhoto != nil && self.video != nil
        } 
    }
    
    func fetchPlayVideoURL(allowLoading: Bool = true, completion: @escaping (URL?) -> Void) {
        if let videoURL = video {
            if videoWasRecorded {
                if let url = URL(string: videoURL) {
                    completion(url)
                }
            } else {
                if allowLoading {
                    let result = VideosProvider.provider.hasVideoFile(with: videoURL)
                    if result.localVideoExist {
                        completion(result.localVideoURL)
                    } else {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            VideosProvider.provider.videoFile(videoURL: videoURL) { url in
                                if let url = url {
                                    completion(url)
                                } else {
                                    completion(InternalExpert.defaultVideoURL)
                                }
                            }
//                        }
                    }
                } else {
                    if let url = URL(string: videoURL) {
                        completion(url)
                    } else {
                        completion(InternalExpert.defaultVideoURL)
                    }
                }
            }
        } else {
            completion(InternalExpert.defaultVideoURL)
        }
    }
}
