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
	private var myContext = 0

	// UI Elements
	@IBInspectable var lckControlView:LockControlView!
	@IBOutlet weak var activityLabel: UILabel!

	// When application loads, and when view appears or disappears
	override func viewDidLoad() {
		super.viewDidLoad()
		self.setNeedsStatusBarAppearanceUpdate()
		
		// Start Bluetooth Central Manager
		smrtLock.startUpCentralManager()
		
		// Add LockControl
		var lockControlTap = UITapGestureRecognizer(target: self, action: Selector("lockControlTapped:"))
		lckControlView = LockControlView(frame: CGRectMake(view.center.x - 150.0, view.center.y - 150.0, 300.0, 300.0))
		lckControlView.addGestureRecognizer(lockControlTap)
		lckControlView.lockStatus = smrtLock.lockStatus
		view.addSubview(lckControlView)
		
		// Watch for changes in "activity" from SmartLock model
		smrtLock.addObserver(self, forKeyPath: "activity", options: .New, context: &myContext)
	}
	
	override func viewDidAppear(animated: Bool) {
		smrtLock.discoverDevices()
	}
	
	override func viewDidDisappear(animated: Bool) {
		smrtLock.disconnectFromSmartLock()
	}
	
	// Set status bar to light
	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}
	
	// Update lockControl text with activity changes in SmartLock model (MVC)
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
		if context == &myContext {
			activityLabel.text = "\(smrtLock.activity)\n"
			lckControlView.determineColor(smrtLock.connectState, lockStatus: smrtLock.lockStatus)
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	
	// Toggle lock/unlock
	func lockControlTapped(recognizer: UITapGestureRecognizer) {
		lckControlView.lockStatus = smrtLock.lockStatus
		
		if (smrtLock.connectState == true) {
			if (smrtLock.lockStatus == Status.Locked) {
				smrtLock.unlockSmartLock()
				lckControlView.determineColor(smrtLock.connectState, lockStatus: smrtLock.lockStatus)
				lckControlView.animateLockControl(1.5)
			} else if (smrtLock.lockStatus == Status.Unlocked) {
				smrtLock.lockSmartLock()
				lckControlView.determineColor(smrtLock.connectState, lockStatus: smrtLock.lockStatus)
				lckControlView.animateLockControl(1.5)
			}
		} else {
			lckControlView.determineColor(smrtLock.connectState, lockStatus: smrtLock.lockStatus)
			smrtLock.discoverDevices()
		}
	}
	
}