//
//  ViewController.swift
//  SmartLock iOS Application
//
//  Created by Elliot Barer on 2014-10-09.
//  Copyright (c) 2014 Elliot Barer. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
	@IBOutlet weak var textField:UITextView!		// Interface text view
	@IBOutlet weak var proximitySwitch:UISwitch!

	var smtLock = SmartLock()
	var activityOld:String?
	
	// When application loads, start Bluetooth
	override func viewDidLoad() {
		super.viewDidLoad()
		smtLock.startUpCentralManager()
		proximitySwitch.on = false
		var consoleTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: Selector("updateConsole"), userInfo: nil, repeats: true)
	}

	@IBAction func lockButton() {
		smtLock.lockSmartLock()
	}
	
	@IBAction func unlockButton() {
		smtLock.unlockSmartLock()
	}
	
	func updateConsole() {
		if (smtLock.activity != activityOld) {
			textField.selectable = false
			textField.text = "\(smtLock.activity)\n" + textField.text
			activityOld = smtLock.activity
		}
	}
	
	@IBAction func connectSmartLock(sender: UIButton) {
		smtLock.discoverDevices()
	}
	
	@IBAction func disconnectSmartLock(sender: UIButton) {
		// Lock before disconnecting
		smtLock.lockSmartLock()
		smtLock.disconnectDevices()
	}
	
	@IBAction func toggleProximity(proximity: UISwitch) {
		if (proximity.on) {
			smtLock.rssiTimerEnable()
		} else {
			smtLock.rssiTimerDisable()
		}
	}
	
	// Clear debug log
	@IBAction func clearLog(sender: UIButton) {
		textField.text = ""
	}
	
}