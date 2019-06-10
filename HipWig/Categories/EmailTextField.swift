//
//  EmailTextField.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/1/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

@IBDesignable
class EmailTextField: UITextField {
        
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set {
            self.layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable
    var cornerRadius: CGFloat {
        set {
            self.layer.cornerRadius = newValue
        }
        get {
            return self.layer.cornerRadius
        }
    }
    
    var cleanSelectedClosure: () -> Void = {}
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rightViewRect = super.rightViewRect(forBounds: bounds)
        rightViewRect.origin.x -= 10;
        return rightViewRect
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.onLoad()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.onLoad()
    }
    
    private func onLoad() {
        
    }
        
}

extension EmailTextField {
    
    func clearButtonWithImage(_ image: UIImage,
                              _ imageColor: UIColor = UIColor.white,
                              _ isAlwaysVisible: Bool = false) {
        let clearButton = UIButton()
        clearButton.tintColor = imageColor
        let coloredImage = image.withRenderingMode(.alwaysTemplate)
        clearButton.setImage(coloredImage, for: .normal)
        clearButton.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
        clearButton.contentMode = .scaleAspectFit
        clearButton.addTarget(self, action: #selector(clear(_:)), for: .touchUpInside)
        
        self.rightView = clearButton
        self.rightViewMode = isAlwaysVisible ? .always : .never
    }
    
    @objc func clear(_ sender: AnyObject) {
        self.text = ""
        self.cleanSelectedClosure()
    }
    
}
