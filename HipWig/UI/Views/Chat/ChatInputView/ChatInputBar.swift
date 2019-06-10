//
//  ChatInputBar.swift
//  HipWig
//
//  Created by Alexey on 1/24/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol ChatInputBarDelegate: class {
    func onSendButtonAction(text: String)
    func onTextChanged(with text: String)
}

class ChatInputBar: UIView {

    @IBOutlet public weak var textView: ChatTextView!
    @IBOutlet public weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet public weak var sendButton: UIButton!
    @IBOutlet public weak var textViewHolder: UIView!
    @IBOutlet public weak var separatorLine: UIView!

    public weak var delegate: ChatInputBarDelegate?

    public func updateLayout() {
        let textHeight = self.textView.actualContentHeight()
        self.textViewHeight.constant = textHeight
        
    }

    public func enableSendButton() {
        self.sendButton.isEnabled = true
    }

    public func disableSendButton() {
        self.sendButton.isEnabled = false
    }

    override var layoutMargins: UIEdgeInsets {
        get {
            return .zero
        }
        set {
            super.layoutMargins = newValue
        }
    }
    
    override var tintColor: UIColor! {
        didSet {
            self.sendButton.tintColor = tintColor
            self.textView.tintColor = UIColor(red: 69, green: 79, blue: 99)
        }
    }

    var isEnabled: Bool = false {
        didSet {
            let color: UIColor = isEnabled ? .white : UIColor.white.withAlphaComponent(0.2)
            
            self.textViewHolder.backgroundColor = color
            self.textView.isUserInteractionEnabled = isEnabled
            self.sendButton.isUserInteractionEnabled = isEnabled
            self.separatorLine.backgroundColor = isEnabled ? separatorLineColor : separatorLineColorWhenHidden
        }
    }
    
    var sendButtonEnabled: Bool = false {
        didSet {
            self.sendButton.isHidden = !sendButtonEnabled
            self.separatorLine.isHidden = !sendButtonEnabled
        }
    }
    
    private var isKeyboardHidden: Bool = true
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonSetup()
    }
    
    private let separatorLineColor = UIColor(red: 234, green: 234, blue: 234)
    private let separatorLineColorWhenHidden = UIColor.clear

    private func commonSetup() {
        let view = Bundle.main.loadNibNamed("ChatInputBar", owner: self, options: nil)?[0] as! UIView
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)

        view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0.0).isActive = true
        view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.0).isActive = true
        view.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0).isActive = true

        self.textView.placeholder = "chat.type_message_placeholder".localized
        self.textViewHolder.layer.masksToBounds = true
        self.textViewHolder.layer.cornerRadius = 12.0
        
        self.textView.backgroundColor = .clear
        self.sendButton.setImage(UIImage(named: "send_button_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.tintColor = UIColor(red: 69, green: 79, blue: 99)
        
        self.sendButtonEnabled = false
        
        NotificationCenter.addDidShowKeyboardObserver { [weak self] in
            guard let `self` = self else { return }
            
            self.isKeyboardHidden = false
            self.sendButtonEnabled = true
        }
        
        NotificationCenter.addHideKeyboardObserver { [weak self] in
            guard let `self` = self else { return }
            
            let text = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            self.isKeyboardHidden = true
            self.sendButtonEnabled = !text.isEmpty
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.textView.reloadInputViews()
    }
    
    func clear() {
        self.textView.text.removeAll()
        self.textView.layoutSubviews()
        
        self.tintColor = UIColor(red: 69, green: 79, blue: 99)
    }

    @IBAction private func sendButtonDidPressed(sender: UIButton) {
        let text = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.delegate?.onSendButtonAction(text: text)
        
        if self.isKeyboardHidden {
            self.sendButtonEnabled = false
        }
    }
}

//MARK: - UITextViewDelegate
extension ChatInputBar: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let enteredText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        self.delegate?.onTextChanged(with: enteredText)
        
        return true
    }
}
