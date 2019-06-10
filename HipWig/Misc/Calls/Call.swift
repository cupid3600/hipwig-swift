//
//  HWCall.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/10/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import OpenTok

enum CallError: Error {
    case unknown(Error)
    case getPublisher
    case getSubscriber
    case getSession
    case createSession
    case createPublisher
}

class Call: NSObject, OTSubscriberKitDelegate {
    
    private (set) var otSession: OTSession?
    private (set) var otPublisher: OTPublisher?
    private (set) var otSubscriber: OTSubscriber?
    
    var isPublishingVideo: Bool {
        if let publisher = self.otPublisher {
            return publisher.publishVideo
        } else {
            return false
        }
    }
    
    var isPublishingAudio: Bool {
        if let publisher = self.otPublisher {
            return publisher.publishAudio
        } else {
            return false
        }
    }
    
    var subscriberDidConnectClosure: (UIView?) -> Void = { _ in }
    var subscriberVideoEnabledClosure: () -> Void = {}
    var subscriberVideoDisabledClosure: () -> Void = {}
    var subscriberDidReconnectClosure: () -> Void = {}
    var subscriberDidDisconnectClosure: () -> Void = {}
    
    var publisherStreamDidDestroyClosure: (OTStream) -> Void = { _ in }
    var publisherDidCreateClosure: () -> Void = { }
    var publisherDidConnectToStreamClosure: (UIView?) -> Void = { _ in }
    
    var sessionDidConnectClosure: () -> Void = {}
    var sessionStreamDidCreateClosure: (OTStream) -> Void = { _ in }
    var sessionStreamDidDestroyClosure: (OTStream) -> Void = { _ in }
    var sessionDidConnectionDestroyClosure: () -> Void = {}
    var prevAudioStateClosure: () -> Bool = { return false }
    
    private let data: StreamData
    private var shouldResumeVideo = true
    private var prevAudioState: Bool? = nil
    private var subscriberStreamIdentifier: String?
    private var timer: RepeatTimer?
    
    init(streamData: StreamData) {
        self.data = streamData
        super.init()
        
        self.onLoad()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    private func onLoad() {
        NotificationCenter.addApplicationDidBecomeActiveObserver { [weak self, weak otSession] in
            guard let `self` = self else { return }
            
            do {
                var streamToSubscribe: OTStream?
                
                let availableStreams = otSession?.streams.values.map{ $0 } ?? []
                if let streamId = self.subscriberStreamIdentifier {
                    if let stream = availableStreams.first(where: { $0.streamId == streamId }) {
                        streamToSubscribe = stream
                    } else if let stream = availableStreams.first {
                        streamToSubscribe = stream
                    }
                } else if let stream = availableStreams.first {
                    streamToSubscribe = stream
                }
                
                if let stream = streamToSubscribe {
                    try self.createSubscriber(for: stream)
                }
                
            } catch let error {
                self.resolve(error: error)
            }
            
//            if let state = self.prevAudioState {
//                self.toggleSpeaker(!state)
//            }
            self.timer = RepeatTimer()
        }
        
        NotificationCenter.addApplicationResignActiveObserver { [weak self, weak otPublisher, weak otSubscriber] in
            guard let `self` = self else { return }
            
            self.prevAudioState = self.prevAudioStateClosure()
            self.shouldResumeVideo = otPublisher?.publishVideo ?? false
            self.subscriberStreamIdentifier = otSubscriber?.stream?.streamId
        }
    }
    
    func set(publishVideo: Bool) {
        self.shouldResumeVideo = publishVideo
        self.otPublisher?.publishVideo = publishVideo
    }
    
    func set(publishAudio: Bool) {
        self.otPublisher?.publishAudio = publishAudio
    }
    
    func toggleCamera() {
        guard let publisher = self.otPublisher else { return }
        
        if publisher.cameraPosition == .back {
            publisher.cameraPosition = .front
        } else if publisher.cameraPosition == .front {
            publisher.cameraPosition = .back
        }
    }
    
    func createSession(streamData: StreamData) throws {
        if let session = OTSession(apiKey: kTokBoxKeyAPI, sessionId: streamData.session, delegate: self) {
            self.otSession = session
        } else {
            throw CallError.createSession
        }
    }
    
    func createPublisher(publishVideo: Bool) throws {
        self.shouldResumeVideo = publishVideo
        
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        settings.videoTrack = true
        settings.audioTrack = true
        
        if let publisher = OTPublisher(delegate: self, settings: settings) {
            publisher.publishVideo = publishVideo
            publisher.publishAudio = true
            
            self.otPublisher = publisher
            self.publisherDidCreateClosure()
            
//            //FIXME: КОСТЫЛЯКА
//            self.timer?.start { [weak self] in
//                guard let `self` = self else {
//                    return
//                }
//                
//                let state = self.prevAudioStateClosure()
//                self.toggleSpeaker(state)
//            }
        } else {
            throw CallError.createPublisher
        }
        
        try self.connectToSession()
    }
    
    func destroySession() {
        var error: OTError?
        
        self.removePublisher()
        self.removeSubscriber()
        
        self.otSession?.disconnect(&error)
        self.otSession = nil
        
        if let error = error {
            self.resolve(error: error)
        }
    }
    
    private func toggleSpeaker(_ state: Bool) {
        let port: AVAudioSession.PortOverride = state ? .speaker : .none
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: .allowBluetooth)
            try audioSession.setActive(true)
            
            try audioSession.overrideOutputAudioPort(port)
            
        } catch {
            logger.log(error)
        }
    }
    
    private func connectToSession() throws {
        if let session = self.otSession {
            var error: OTError?
            session.connect(withToken: self.data.token, error: &error)
            
            if let error = error {
                throw CallError.unknown(error)
            }
        } else {
            throw CallError.getSession
        }
    }
    
    private func publish() throws {
        if let session = self.otSession {
            if let publisher = self.otPublisher {
                var error: OTError?
                
                session.publish(publisher, error: &error)
                
                if let error = error {
                    throw CallError.unknown(error)
                } else { 
                    self.publisherDidConnectToStreamClosure(publisher.view)
                }
            } else {
                throw CallError.getPublisher
            }
        } else {
            throw CallError.getSession
        }
    }
    
    private func createSubscriber(for stream: OTStream) throws {
        if let session = self.otSession {
            if let subscriber = OTSubscriber(stream: stream, delegate: self) {
                var error: OTError?
                session.subscribe(subscriber, error: &error)
                
                if let error = error {
                    throw CallError.unknown(error)
                } else {
                    self.otSubscriber = subscriber
                }
            } else {
                throw CallError.getSubscriber
            }
        } else {
            throw CallError.getSession
        }
    }
    
    private func resolve(error: Error) {
        logger.log(error)
    }
    
    fileprivate func removeSubscriber() {
        self.otSubscriber?.view?.removeFromSuperview()
        self.otSubscriber = nil
    }
    
    fileprivate func removePublisher() {
        self.otPublisher?.view?.removeFromSuperview()
        self.otPublisher = nil
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        logger.log(error)
    }
    
    func subscriberVideoEnabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
        self.subscriberVideoEnabledClosure()
    }
    
    func subscriberVideoDisabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
        self.subscriberVideoDisabledClosure()
    }
    
    func subscriberDidReconnect(toStream subscriber: OTSubscriberKit) {
        self.subscriberDidReconnectClosure()
    }
    
    func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {
        self.subscriberDidDisconnectClosure()
    }
}

extension Call: OTSubscriberDelegate {
    
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        self.subscriberDidConnectClosure(self.otSubscriber?.view)
    }
}

extension Call: OTPublisherDelegate {
    
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        print("[timer] stream stream destroyed")
        
        self.removePublisher()
        
        if let subStream = self.otSubscriber?.stream, subStream.streamId == stream.streamId {
            self.removeSubscriber()
        }
        
        self.publisherStreamDidDestroyClosure(stream)
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        self.resolve(error: error)
    }
}

extension Call: OTSessionDelegate {
    
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        
        self.sessionDidConnectClosure()
        
        do {
            try self.publish()
        } catch let error {
            self.resolve(error: error)
        }
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        
        self.sessionStreamDidCreateClosure(stream)
        
        if self.otSubscriber == nil {
            do {
                try self.createSubscriber(for: stream)
            } catch let error {
                self.resolve(error: error)
            }
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        self.sessionStreamDidDestroyClosure(stream)
        
        print("[timer] stream stream destroyed")
        
        if let subscriberStream = self.otSubscriber?.stream, subscriberStream.streamId == stream.streamId {
            self.removeSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        self.resolve(error: error)
    }
    
    func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
        print("[timer] connectionDestroyed")
        
        self.destroySession()
        self.sessionDidConnectionDestroyClosure()
    }
    
    func sessionDidReconnect(_ session: OTSession) {
        print(#function)
    }
    
    func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
        print(type ?? "" + " " + (string ?? ""))
    }
}
