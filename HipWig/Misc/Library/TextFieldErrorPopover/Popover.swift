//
//  Popover.swift
//  KettlebellTimer
//
//  Created by Vladyslav Shepitko on 9/13/18.
//  Copyright © 2018 mobiledev. All rights reserved.
//

import UIKit
import KUIPopOver

class Popover: UIViewController, KUIPopOverUsable {

    @IBOutlet weak var errorLabel: UILabel!
    
    private var popoverHeight: CGFloat = 0.0
    private var popoverWidth: CGFloat = 200.0
    private var errorMessage: String?
    var contentSize: CGSize {
        return CGSize(width: popoverWidth, height: popoverHeight)
    }
    
    var arrowDirection: UIPopoverArrowDirection { return .up }
    
    var popOverBackgroundColor: UIColor? { return .white }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    } 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.text = errorMessage
    }
    
    func setError(error: String) {
        popoverHeight = error.height(withConstrainedWidth: popoverWidth, font: UIFont.systemFont(ofSize: 24))
        errorMessage = error
    }
}

private extension String {
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let frame = NSString(string: self).boundingRect(
            with: CGSize(width: width, height: .infinity),
            options: [.usesFontLeading, .usesLineFragmentOrigin],
            attributes: [.font : font],
            context: nil)
        
        return frame.size.height
    }
    
}

