//
//  AVSession+ChangeRoute.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/8/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension AVAudioSession {
    
    func changeAudioOutput(_ presenterViewController : UIViewController, some: @escaping (Bool) -> Void) {

        let IPHONE_TITLE = "iPhone"
        let HEADPHONES_TITLE = "Headphones"
        let SPEAKER_TITLE = "Speaker"
        let HIDE_TITLE = "Hide"
        
        var deviceAction = UIAlertAction()
        var headphonesExist = false
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for input in self.availableInputs! {
            
            switch input.portType {
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                let action = UIAlertAction(title: input.portName, style: .default) { (action) in
                    some(true)
                    do {
                        // remove speaker if needed
                        try self.overrideOutputAudioPort(.none)
                        
                        // set new input
//                        try self.setPreferredInput(nil)
                        try self.setPreferredInput(input)
//                        try self.setActive(true)
                    } catch let error as NSError {
                        logger.log(error)
                        print("audioSession error change to input: \(input.portName) with error: \(error.localizedDescription)")
                    }
                }

                optionMenu.addAction(action)
                
                break
                
            case .builtInMic, .builtInReceiver:
                deviceAction = UIAlertAction(title: IPHONE_TITLE, style: .default) { (action) in
                    some(false)
                    
                    do {
                        // remove speaker if needed
                        try self.overrideOutputAudioPort(.none)
                        
                        // set new input
//                        try self.setPreferredInput(nil)
                        try self.setPreferredInput(input) 
                    } catch let error as NSError {
                        logger.log(error)
                        print("audioSession error change to input: \(input.portName) with error: \(error.localizedDescription)")
                    }
                }

                break
                
            case .headphones, .headsetMic:
                headphonesExist = true
                let action = UIAlertAction(title: HEADPHONES_TITLE, style: .default) { (action) in
                    some(false)
                    
                    do {
                        // remove speaker if needed
                        try self.overrideOutputAudioPort(.none)
                        
                        // set new input
                        try self.setPreferredInput(input)
                    } catch let error as NSError {
                        logger.log(error)
                        print("audioSession error change to input: \(input.portName) with error: \(error.localizedDescription)")
                    }
                }
                
                optionMenu.addAction(action)
                
                break
                
            default:
                break
            }
        }
        
        if !headphonesExist {
            optionMenu.addAction(deviceAction)
        }
        
        let speakerOutput = UIAlertAction(title: SPEAKER_TITLE, style: .default) { alert in
            some(false)
            
            do {
                try self.overrideOutputAudioPort(.speaker)
//                try self.setActive(true)
            } catch let error as NSError {
                logger.log(error)
                print("audioSession error turning on speaker: \(error.localizedDescription)")
            }
            
        }
        
        optionMenu.addAction(speakerOutput)
        let cancelAction = UIAlertAction(title: HIDE_TITLE, style: .cancel)
        optionMenu.addAction(cancelAction)
        
        presenterViewController.present(optionMenu, animated: true)
        
    }

}
