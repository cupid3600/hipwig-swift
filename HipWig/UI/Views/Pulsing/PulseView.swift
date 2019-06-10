//
//  PulseView.swift
//  HipWig
//
//  Created by Alexey on 1/31/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class PulseView: UIView {
    
    @IBInspectable public var pulseCount: Int = 3
    @IBInspectable public var pulseInterval: Double = 0.2
    @IBInspectable public var pulseLineColor: UIColor = .blue
    @IBInspectable public var contentImageName: String = ""

    private var pulseArray: [CAShapeLayer] = []
    private var contentImageView = UIImageView()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        onLoad()
    }

    public func start() {
        self.stop()
        self.createPulseWaves()
    }

    public func stop() {
        for animation in self.pulseArray {
            animation.removeFromSuperlayer()
        }
        self.pulseArray.removeAll()
    }

    private func onLoad() {
        self.contentImageView.image = UIImage(named: self.contentImageName)

        self.addSubview(self.contentImageView)
        self.contentImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.contentImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.contentImageView.widthAnchor.constraint(equalToConstant: 72.0.adjusted).isActive = true
        self.contentImageView.heightAnchor.constraint(equalToConstant: 72.0.adjusted).isActive = true
    }

    private func createPulseWaves() {

        for _ in 0 ..< pulseCount {
            let circularPath = UIBezierPath(arcCenter: .zero, radius: self.bounds.width / 2, startAngle: 0, endAngle: 2 * .pi , clockwise: true)
            let pulsatingLayer = CAShapeLayer()
            pulsatingLayer.path = circularPath.cgPath
            pulsatingLayer.lineWidth = 3
            pulsatingLayer.fillColor = UIColor.clear.cgColor

            pulsatingLayer.lineCap = CAShapeLayerLineCap.round

            pulsatingLayer.position = CGPoint(x: self.frame.size.width / 2.0, y: self.frame.size.height / 2.0)

            self.layer.addSublayer(pulsatingLayer)

            pulseArray.append(pulsatingLayer)
        }

        for i in 0 ..< pulseCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + (TimeInterval(i) * self.pulseInterval), execute: {
                self.animatePulsatingLayerAt(index: i)
            })
        }
    }


    private func animatePulsatingLayerAt(index: Int) {
        if self.pulseArray.isEmpty {
            return
        }

        //Giving color to the layer
        self.pulseArray[index].strokeColor = self.pulseLineColor.cgColor

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.7
        scaleAnimation.toValue = 1.2

        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        opacityAnimation.fromValue = 0.9
        opacityAnimation.toValue = 0.0

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [scaleAnimation, opacityAnimation]
        groupAnimation.duration = 2.5
        groupAnimation.repeatCount = .greatestFiniteMagnitude
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        self.pulseArray[index].add(groupAnimation, forKey: "groupanimation")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for layer in self.pulseArray {
            layer.position = CGPoint(x: self.frame.size.width / 2.0, y: self.frame.size.height / 2.0)
        }
    }
}
