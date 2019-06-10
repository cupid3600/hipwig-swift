//
//  UITextField+Error.swift
//  CoinIndex
//
//  Created by Vladyslav Shepitko on 12/3/18.
//  Copyright © 2018 Sergey Yavorsky. All rights reserved.
//

import UIKit

private var errorViewKey: UInt8 = 0
private var errorMessageKey: UInt8 = 1

extension UITextField {
    
    private var errorView: UIView? {
        get {
            return objc_getAssociatedObject(self, &errorViewKey) as? UIView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &errorViewKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    private var errorMessage: String? {
        get {
            return objc_getAssociatedObject(self, &errorMessageKey) as? String
        }
        set(newValue) {
            objc_setAssociatedObject(self, &errorMessageKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    func show(error: String?) {
        errorMessage = error
        if error != nil {
            if errorView == nil {
                let errorView = createErrorView()
                self.errorView = errorView
                
                createErrorButtonConstraints(for: errorView)
            }
        } else {
            errorView?.removeFromSuperview()
            errorView = nil
        }
    }
    
    private func createErrorButtonConstraints(for errorView: UIView) {
        addSubview(errorView)
        
        errorView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        errorView.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
        errorView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        errorView.widthAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    private func createErrorView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .infoLight)
        button.addTarget(self, action: #selector(infoSelected(_:)), for: .touchUpInside)
        button.tintColor = .red
        view.place(button)
        
        return view
    }
    
    @objc func infoSelected(_ sender: UIButton) {
        if let error = errorMessage {
            ErrorDetailsPopover.hide()
            ErrorDetailsPopover.show(from: sender, with: error)
        } else {
            ErrorDetailsPopover.hide()
        }
    }
}
