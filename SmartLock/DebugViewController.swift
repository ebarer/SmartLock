//
//  DebugViewController.swift
//  SmartLock iOS Application
//
//  Created by Elliot Barer on 2014-10-09.
//  Copyright (c) 2014 Elliot Barer. All rights reserved.
//

import UIKit

class DebugViewController: UIViewController {
	
	// UI Elements
	@IBOutlet weak var textField:UITextView!
	@IBOutlet weak var proximitySwitch:UISwitch!
	@IBOutlet weak var lockThresholdSlider: UISlider!
	@IBOutlet weak var lockThresholdLabel: UILabel!
	@IBOutlet weak var unlockThresholdSlider: UISlider!
	@IBOutlet weak var unlockThresholdLabel: UILabel!

	private var myContext = 0
	var smtLock = SmartLock()
	
	// When application loads
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Start bluetooth central manager
		smtLock.startUpCentralManager()
		
		// Disable proximity (for demonstration)
		proximitySwitch.on = false
		lockThresholdSlider.value = Float(smtLock.lockThreshold)
		lockThresholdLabel.text = "Lock Threshold = \(smtLock.lockThreshold)"
		unlockThresholdSlider.value = Float(smtLock.unlockThreshold)
		unlockThresholdLabel.text = "Unlock Threshold = \(smtLock.unlockThreshold)"
		
		// Watch for changes in "activity" from SmartLock model (for debug console)
		smtLock.addObserver(self, forKeyPath: "activity", options: .New, context: &myContext)
	}
	
	// Update debug console with activity changes in SmartLock model (MVC)
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
		if context == &myContext {
			textField.selectable = false
			textField.text = "\(smtLock.activity)\n" + textField.text
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	
	// When application quits, remove "activity" observer
	deinit {
		smtLock.removeObserver(self, forKeyPath: "activity", context: &myContext)
	}

	// Toggle lock
	@IBAction func lockButton() {
		smtLock.lockSmartLock()
	}
	
	// Toggle unlock
	@IBAction func unlockButton() {
		smtLock.unlockSmartLock()
	}
	
	// Conncet to existing SmartLock, or search for new
	@IBAction func connectSmartLock(sender: UIButton) {
		smtLock.discoverDevices()
	}

	// Diconncet SmartLock
	@IBAction func disconnectSmartLock(sender: UIButton) {
		// Lock before disconnecting
		smtLock.lockSmartLock()
		smtLock.disconnectDevices()
	}
	
	// Toggle proximity mode by enabling/disabling the RSSI timer
	@IBAction func toggleProximity(proximity: UISwitch) {
		if (proximity.on) {
			smtLock.rssiTimerEnable()
		} else {
			smtLock.rssiTimerDisable()
		}
	}
	
	// Adjust lock threshold value for proximity mode
	@IBAction func adjustLockThreshold(threshold: UISlider) {
		smtLock.lockThreshold = Int(threshold.value)
		lockThresholdLabel.text = "Lock Threshold = \(Int(threshold.value))"
	}

	// Adjust unlock threshold value for proximity mode
	@IBAction func adjustUnlockThreshold(threshold: UISlider) {
		smtLock.unlockThreshold = Int(threshold.value)
		unlockThresholdLabel.text = "Unlock Threshold = \(Int(threshold.value))"
	}
	
	// Clear debug log
	@IBAction func clearLog(sender: UIButton) {
		textField.text = ""
	}
	
}