//
//  ErrorDetailsPopover.swift
//  KettlebellTimer
//
//  Created by Vladyslav Shepitko on 9/13/18.
//  Copyright © 2018 mobiledev. All rights reserved.
//

import UIKit

private var popoverKey: UInt8 = 0
class ErrorDetailsPopover {
    
    private static var popover: Popover? {
        get {
            return objc_getAssociatedObject(self, &popoverKey) as? Popover
        }
        set(newValue) {
            objc_setAssociatedObject(self, &popoverKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    static func show(from sender: UIView, with error: String) {
        self.popover = ModalStoryboard.errorPopover
        self.popover?.setError(error: error)
        self.popover?.showPopover(sourceView: sender)
    }
    
    static func hide() {
        popover?.dismissPopover(animated: true)
    }
}

