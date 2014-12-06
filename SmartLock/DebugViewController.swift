//
//  DebugViewController.swift
//  SmartLock iOS Application
//
//  Created by Elliot Barer on 2014-10-09.
//  Copyright (c) 2014 Elliot Barer. All rights reserved.
//

import UIKit

class DebugViewController: UIViewController {
	
	var smrtLock = SmartLock()
	private var myContext = 0
	
	// UI Elements
	@IBOutlet weak var textField:UITextView!
	@IBOutlet weak var proximitySwitch:UISwitch!
	@IBOutlet weak var lockThresholdSlider:UISlider!
	@IBOutlet weak var lockThresholdLabel:UILabel!
	@IBOutlet weak var unlockThresholdSlider:UISlider!
	@IBOutlet weak var unlockThresholdLabel:UILabel!
	
	// When application loads
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Start Bluetooth Central Manager
		smrtLock.startUpCentralManager()
		
		// Disable proximity (for demonstration)
		proximitySwitch.on = false
		lockThresholdSlider.value = Float(smrtLock.lockThreshold)
		lockThresholdLabel.text = "Lock Threshold = \(smrtLock.lockThreshold)"
		unlockThresholdSlider.value = Float(smrtLock.unlockThreshold)
		unlockThresholdLabel.text = "Unlock Threshold = \(smrtLock.unlockThreshold)"
		
		// Watch for changes in "activity" from SmartLock model (for debug console)
		smrtLock.addObserver(self, forKeyPath: "activity", options: .New, context: &myContext)
	}
	
	// Update debug console with activity changes in SmartLock model (MVC)
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
		if context == &myContext {
			textField.selectable = false
			textField.text = "\(smrtLock.activity)\n" + textField.text
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}

	// Toggle lock
	@IBAction func lockButton() {
		smrtLock.lockSmartLock()
	}
	
	// Toggle unlock
	@IBAction func unlockButton() {
		smrtLock.unlockSmartLock()
	}
	
	// Conncet to existing SmartLock, or search for new
	@IBAction func connectSmartLock(sender: UIButton) {
		smrtLock.discoverDevices()
	}

	// Diconncet SmartLock
	@IBAction func disconnectSmartLock(sender: UIButton) {
		// Lock before disconnecting
		smrtLock.lockSmartLock()
		smrtLock.disconnectFromSmartLock()
	}
	
	// Toggle proximity mode by enabling/disabling the RSSI timer
	@IBAction func toggleProximity(proximity: UISwitch) {
		if (proximity.on) {
			smrtLock.rssiTimerEnable()
		} else {
			smrtLock.rssiTimerDisable()
		}
	}
	
	// Adjust lock threshold value for proximity mode
	@IBAction func adjustLockThreshold(threshold: UISlider) {
		smrtLock.lockThreshold = Int(threshold.value)
		lockThresholdLabel.text = "Lock Threshold = \(Int(threshold.value))"
	}

	// Adjust unlock threshold value for proximity mode
	@IBAction func adjustUnlockThreshold(threshold: UISlider) {
		smrtLock.unlockThreshold = Int(threshold.value)
		unlockThresholdLabel.text = "Unlock Threshold = \(Int(threshold.value))"
	}
	
	// Clear debug log
	@IBAction func clearLog(sender: UIButton) {
		textField.text = ""
	}

	// When application quits, remove "activity" observer
	deinit {
		smrtLock.removeObserver(self, forKeyPath: "activity", context: &myContext)
	}
	
}