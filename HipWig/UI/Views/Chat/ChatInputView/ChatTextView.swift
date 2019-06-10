//
//  ChatTextView.swift
//  HipWig
//
//  Created by Alexey on 1/24/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class ChatTextView: UITextView {

    public var placeholder: String? {
        get {
            return self.placeholderLabel.text
        }
        set {
            self.placeholderLabel.text = newValue
            self.setNeedsLayout()
        }
    }

    public var maxNumberOfLines: Int = 0
    public var currentNumberOfLines: Int {
        get {
            let contentSize = self.contentSize

            var contentHeight = contentSize.height
            contentHeight -= self.textContainerInset.top + self.textContainerInset.bottom
            var lines = Int(abs(contentHeight / self.font!.lineHeight))
            if lines == 0 {
                lines = 1
            }
            return lines
        }
    }
    
    override var contentSize: CGSize {
        didSet {
            contentInset = .zero
        }
    }
    
    public var snapScrollPositionToInput = false

    private var placeholderLabel = UILabel()
    private var observation: NSKeyValueObservation?
    private var lineHeight: CGFloat {
        if let font = self.font {
            return CGFloat(ceilf(Float(font.lineHeight)))
        } else {
            return 1.0
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    private func setup() {
        self.font = Font.regular.of(size: 14)
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.textContainerInset = .zero

        self.maxNumberOfLines = 3

        self.placeholderLabel.clipsToBounds = false
        self.placeholderLabel.numberOfLines = 1
        self.placeholderLabel.autoresizesSubviews = false
        self.placeholderLabel.font = self.font
        self.placeholderLabel.backgroundColor = UIColor.clear
        self.placeholderLabel.textColor = UIColor(red: 120, green: 132, blue: 158)
        self.placeholderLabel.isHidden = true
        
        let insets = UIEdgeInsets(top: 0, left: self.textContainer.lineFragmentPadding, bottom: 0, right: 0)
        self.place(self.placeholderLabel, insets: insets)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeText(notification:)), name: UITextView.textDidChangeNotification, object: nil)
        self.addObserver(self, forKeyPath:#keyPath(UITextView.contentSize), options: [NSKeyValueObservingOptions.new], context: nil)
    }

    override var intrinsicContentSize: CGSize {
        var height = self.font!.lineHeight
        height += self.textContainerInset.top + self.textContainerInset.bottom
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    open class func requiresConstraintBasedLayout() -> Bool {
        return true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.placeholderLabel.isHidden = self.shouldHidePlaceholder()

        if self.snapScrollPositionToInput {
            var verticalOffset = self.contentSize.height - self.bounds.size.height
            let inputFrame = self.firstRect(for: self.selectedTextRange!)
            if inputFrame.origin.y == CGFloat.infinity || inputFrame.size.height == CGFloat.infinity {
                verticalOffset = self.contentSize.height - self.bounds.size.height
            } else {
                verticalOffset = inputFrame.origin.y - inputFrame.size.height - self.lineHeight
            }
            
            self.contentOffset = CGPoint(x: 0.0, y: max(0, verticalOffset))
        }

        if self.placeholderLabel.isHidden == false {
            UIView.performWithoutAnimation {
                self.sendSubviewToBack(self.placeholderLabel)
            }
        }
    }

    private func shouldHidePlaceholder() -> Bool {
        if self.placeholder?.count == 0 || self.text.count > 0 {
            return true
        }
        
        return false
    } 

    public func actualContentHeight() -> CGFloat {
        let currentLines = self.currentNumberOfLines
        var height: CGFloat = 0.0;
        if currentLines >= self.maxNumberOfLines {
            height = CGFloat(self.maxNumberOfLines) * self.lineHeight + self.textContainerInset.top + self.textContainerInset.bottom
        } else {
            height = self.contentSize.height
        }
        
        return height
    }


    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let temp = object as? ChatTextView

        guard let obj = temp else {
            return
        }
        guard let kp = keyPath else {
            return
        }
        if obj != self {
            return
        }

        if kp == #keyPath(contentSize) {
            NotificationCenter.default.post(name: Notification.Name.ChatTextViewContentSizeDidChanged, object: self, userInfo: nil)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    @objc private func didChangeText(notification: Notification) {
        let temp = notification.object as? ChatTextView
        guard let obj = temp else {
            return
        }
        if obj != self {
            return
        }
        if self.placeholderLabel.isHidden != self.shouldHidePlaceholder() {
            self.setNeedsLayout()
        }
        super.flashScrollIndicators()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.removeObserver(self, forKeyPath: #keyPath(UITextView.contentSize))
    }
}
