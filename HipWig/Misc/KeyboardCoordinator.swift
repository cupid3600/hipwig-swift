//
//  KeyboardCoordinator.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/1/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class KeyboardCoordinator: NSObject {

    private weak var view: UIView?
    private let notificationCenter = NotificationCenter.default
    
    var willShowKeyboardHandler: (CGFloat) -> Void = { _ in }
    var willHideKeyboardHandler: () -> Void = { }
    var didShowKeyboardHandler: () -> Void = { }
    var updateLayoutHandler: () -> Void = {}
    
    
    func update(with view: UIView) {
        self.view = view
    }
    
    func subscribeForKeyboardEvents() {
        self.registerNotifications()
    }
    
    func unsubscribeFromKeyboardEvents() {
        notificationCenter.removeObserver(self)
    }
    
    private func registerNotifications() {
        notificationCenter.addObserver(self,
                                       selector: #selector(textViewContentSizeChanged(notification:)),
                                       name: NSNotification.Name.ChatTextViewContentSizeDidChanged, object: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(keyboardWillShow(notification:)),
                                       name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(keyboardWillHide(notification:)),
                                       name: UIResponder.keyboardWillHideNotification, object: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(keyboardDidShow(notification:)),
                                       name: UIResponder.keyboardDidShowNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        let keyboardSizeNum = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        let keyboardSize = keyboardSizeNum.cgRectValue.size
        let durationNum = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber
        let duration = durationNum.intValue
        let curveNum = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber
        let curve = curveNum.intValue

        let height = keyboardSize.height

        var bottomPadding: CGFloat = 0.0
        if #available(iOS 11.0, *) {
            bottomPadding = view?.safeAreaInsets.bottom ?? 0.0
        }

        self.willShowKeyboardHandler(height - bottomPadding)
        
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: curve)!)
        UIView.animate(withDuration: TimeInterval(duration), animations: {
            self.view?.layoutIfNeeded()
        })
    }

    @objc private func keyboardWillHide(notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        
        let durationNum = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber
        let duration = durationNum.intValue
        let curveNum = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber
        let curve = curveNum.intValue

        self.willHideKeyboardHandler()
        
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: curve)!)
        UIView.animate(withDuration: TimeInterval(duration)) {
            self.view?.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardDidShow(notification: Notification) {
        self.didShowKeyboardHandler()
    }
    
    @objc private func textViewContentSizeChanged(notification: Notification) {
        let temp = notification.object as? ChatTextView
        
        guard let _ = temp else {
            return
        }
        
        self.updateLayoutHandler()
    }
    
}
