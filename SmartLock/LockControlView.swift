//
//  LockControlView.swift
//  SmartLock
//
//  Created by Elliot Barer on 2014-12-05.
//  Copyright (c) 2014 Elliot Barer. All rights reserved.
//

import UIKit

class LockControlView: UIView {
	
//    override func drawRect(rect: CGRect) {
//		// Get the Graphics Context
//		var context = UIGraphicsGetCurrentContext();
//		CGContextSetLineWidth(context, 10);
//		UIColor.redColor().set()
//		CGContextAddArc(context, (frame.size.width)/2, frame.size.height/2, (frame.size.width - 10)/2, 0.0, CGFloat(M_PI * 2.0), 1)
//		CGContextStrokePath(context);
//    }
	
	let lockControlShape = CAShapeLayer()
	let ringAnimation = CABasicAnimation(keyPath: "strokeEnd")
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = UIColor.clearColor()
		
		lockControlShape.path = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: (frame.size.width - 10)/2, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true).CGPath
		lockControlShape.fillColor = UIColor.clearColor().CGColor
		lockControlShape.strokeColor = UIColor.grayColor().CGColor
		
		lockControlShape.lineWidth = 6.0;
		lockControlShape.strokeEnd = 1.0
		
		layer.addSublayer(lockControlShape)
	}
	
	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	func animateLockControl(duration: NSTimeInterval, lockStatus: Status) {
		
		// Set the animation duration appropriately
		ringAnimation.duration = duration
		
		// Animate from 0 to 1, then set endpoint
		ringAnimation.fromValue = 0
		ringAnimation.toValue = 1
		lockControlShape.strokeEnd = 1.0
		
		// Perform linear animation
		ringAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
		
		// Determine ring colour based on lock status
		switch (lockStatus) {
			case Status.Locked:
				lockControlShape.strokeColor = UIColor.redColor().CGColor
			case Status.Unlocked:
				lockControlShape.strokeColor = UIColor.greenColor().CGColor
			default:
				lockControlShape.strokeColor = UIColor.grayColor().CGColor
		}
		
		// Add animation to object
		lockControlShape.addAnimation(ringAnimation, forKey: "animateLockControl")
	}

}
