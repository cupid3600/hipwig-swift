//
//  PulseButton.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 1/30/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

protocol PulseButtonDelegate: class {
    func selectButton()
    func releaseButton()
}

class PulseButton: _PulseView {
    
    weak var delegate: PulseButtonDelegate?
    private var isButtonSelected: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        onLoad()
    }
    
    private lazy var sourceEventButton: UIButton = {
        let button = UIButton()
        button.adjustsImageWhenHighlighted = false
        button.addTarget(self, action: #selector(touchDownButton), for: .touchDown)
        button.addTarget(self, action: #selector(releaseButton), for: .touchUpInside)
        
        return button
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.onLoad()
    }
    
    private func onLoad() {
        self.sourceEventButton.setImage(UIImage(named: "record_video_unselected"), for: .normal)
        self.place(self.sourceEventButton)
    }
    
    private func register(target: UIButton) {
        target.addTarget(self, action: #selector(touchDownButton), for: .touchDown)
        target.addTarget(self, action: #selector(releaseButton), for: .touchUpInside)
    }
    
    @objc func touchDownButton() {
        self.sourceEventButton.setImage(UIImage(named: "record_video_selected"), for: .normal)
        self.isButtonSelected = true
        
        self.start()
        self.delegate?.selectButton()
    }
    
    @objc func releaseButton() {
        if self.isButtonSelected {
            self.delegate?.releaseButton()
        }
        
        self.reset()
    }

    func reset() {
        self.isButtonSelected = false
        self.sourceEventButton.setImage(UIImage(named: "record_video_unselected"), for: .normal)
        self.stop()
    }
}

@IBDesignable
class _PulseView: UIView {
    
    @IBInspectable public var pulseCount: Int = 3
    @IBInspectable public var pulseInterval: Double = 0.2
    @IBInspectable public var lineWidth: CGFloat = 4
    @IBInspectable public var pulseLineColor: UIColor = .blue
    @IBInspectable public var minWaveRadius: CGFloat = 0.8
    @IBInspectable public var maxWaveRadius: CGFloat = 1.5
    
    private var pulseArray: [CAShapeLayer] = []
    
    func start() {
        self.createPulseWaves()
    }
    
    func stop() {
        self.layer.removeAllAnimations()
        
        for animation in pulseArray {
            animation.removeFromSuperlayer()
        }
        
        pulseArray.removeAll()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.pulseArray.forEach { layer in
            layer.position = CGPoint(x: self.frame.size.width / 2.0, y: self.frame.size.height / 2.0)
        }
    }
    
    private func createPulseWaves() {
        
        for _ in 0 ..< pulseCount {
            let circularPath = UIBezierPath(arcCenter: .zero, radius: self.bounds.width / 2, startAngle: 0, endAngle: 2 * .pi , clockwise: true)
            let pulsatingLayer = CAShapeLayer()
            pulsatingLayer.path = circularPath.cgPath
            pulsatingLayer.lineWidth = self.lineWidth
            pulsatingLayer.fillColor = UIColor.clear.cgColor
            pulsatingLayer.lineCap = CAShapeLayerLineCap.round
            pulsatingLayer.position = CGPoint(x: self.frame.size.width / 2.0, y: self.frame.size.height / 2.0)
            
            self.layer.insertSublayer(pulsatingLayer, at: 0)
            
            pulseArray.append(pulsatingLayer)
        }
        
        for i in 0 ..< pulseCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + (TimeInterval(i) * self.pulseInterval), execute: {
                self.animatePulsatingLayerAt(index: i)
            })
        }
    }
    
    
    private func animatePulsatingLayerAt(index: Int) {
        if pulseArray.isEmpty {
            return
        }
        
        //Giving color to the layer
        pulseArray[index].strokeColor = pulseLineColor.cgColor
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = self.minWaveRadius
        scaleAnimation.toValue = self.maxWaveRadius
        
        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        opacityAnimation.fromValue = 0.9
        opacityAnimation.toValue = 0.0
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [scaleAnimation, opacityAnimation]
        groupAnimation.duration = 2.5
        groupAnimation.repeatCount = .greatestFiniteMagnitude
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        pulseArray[index].add(groupAnimation, forKey: "groupanimation")
    }
}
