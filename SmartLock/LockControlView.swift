//
//  LockControlView.swift
//  SmartLock
//
//  Created by Elliot Barer on 2014-12-05.
//  Copyright (c) 2014 Elliot Barer. All rights reserved.
//

import UIKit

class LockControlView: UIView {
	
	let lockControlShape = CAShapeLayer()
	let ringAnimation = CABasicAnimation(keyPath: "strokeEnd")
	var lockStatus:Status!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = UIColor.clearColor()
		
		lockControlShape.path = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: (frame.size.width - 10)/2, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true).CGPath
		lockControlShape.fillColor = UIColor.clearColor().CGColor
		
		lockControlShape.lineWidth = 6.0;
		lockControlShape.strokeEnd = 1.0
		
		layer.addSublayer(lockControlShape)
	}
	
	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	func animateLockControl(duration: NSTimeInterval) {
		
		// Set the animation duration appropriately
		ringAnimation.duration = duration
		
		// Animate from 0 to 1, then set endpoint
		ringAnimation.fromValue = 0
		ringAnimation.toValue = 1
		lockControlShape.strokeEnd = 1.0
		
		// Perform linear animation
		ringAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
		
		// Add animation to object
		lockControlShape.addAnimation(ringAnimation, forKey: "animateLockControl")
	}
	
	// Determine ring colour based on lock status
	func determineColor(connectState: Bool, lockStatus: Status) {
		if(connectState == true) {
			switch (lockStatus) {
				case .Locked:
					lockControlShape.strokeColor = UIColor.redColor().CGColor
				case .Locking:
					lockControlShape.strokeColor = UIColor.redColor().CGColor
				case .Unlocked:
					lockControlShape.strokeColor = UIColor.greenColor().CGColor
				case .Unlocking:
					lockControlShape.strokeColor = UIColor.greenColor().CGColor
				default:
					lockControlShape.strokeColor = UIColor.grayColor().CGColor
			}
		} else {
			lockControlShape.strokeColor = UIColor.grayColor().CGColor
		}
	}

}
