//
//  DebugViewController.swift
//  SmartLock iOS Application
//
//  Created by Elliot Barer on 2014-10-09.
//  Copyright (c) 2014 Elliot Barer. All rights reserved.
//

import UIKit

class SmartLockViewController: UIViewController {

	var smrtLock = SmartLock()
	var lckControlView:LockControlView!

	override func viewDidLoad() {
		super.viewDidLoad()
		self.setNeedsStatusBarAppearanceUpdate()
		
		// Start Bluetooth Central Manager
		smrtLock.startUpCentralManager()
		
		// Add LockControl
		var lockControlTap = UITapGestureRecognizer(target: self, action: Selector("lockControlTapped:"))
		lckControlView = LockControlView(frame: CGRectMake(view.center.x - 150.0, view.center.y - 150.0, 300.0, 300.0))
		lckControlView.addGestureRecognizer(lockControlTap)
		view.addSubview(lckControlView)
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}
	
	func lockControlTapped(recognizer: UITapGestureRecognizer) {
		lckControlView.animateLockControl(1.0, lockStatus: smrtLock.lockStatus)
		
		if (smrtLock.lockStatus == Status.Locked) {
			println("unlocking")
			smrtLock.unlockSmartLock()
		}
		
		if (smrtLock.lockStatus == Status.Unlocked) {
			println("locking")
			smrtLock.lockSmartLock()
		}
	}
	
}