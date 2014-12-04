//
//  ViewController.swift
//  SmartLock iOS Application
//
//  Created by Elliot Barer on 2014-10-09.
//  Copyright (c) 2014 Elliot Barer. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
	
	enum Status {
		case Locked
		case Unlocked
	}
	
	// Bluetooth Communication
	//
	
	
	// Bluetooth Peripheral Heirarchy:
	//
	// CBPeripheral
	//		|
	//		|---- CBService
	//		|		  |
	//		|		  |---- CBCharacteristic
	//		|		  |
	//		|		  |---- CBCharacteristic
	//		|		  |
	//		|		  |			  ...
	//		|
	//		|---- CBService
	//		|
	//		|		 ...

	
	
//*******************************************************
// Class members
//*******************************************************
	var centralManager:CBCentralManager!			// Bluetooth central manager (iOS Device)
	var smartLock:CBPeripheral!						// Bluetooth peripheral device (SmartLock)
	var txCharacteristic:CBCharacteristic!			// Bluetooth TX characteristic
	
	var btState:Bool!								// Bluetooth status
	var btRSSI:NSNumber!							// Bluetooth signal strengh (RSSI)
	var lockStatus:Status!							// SmartLock status
	@IBOutlet weak var textField: UITextView!		// Interface text view
	
	// UUIDs for SmartLock UART Service and Characteristics (RX/TX)
	let uartServiceUUID = CBUUID(string:"6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
	let txCharacteristicUUID = CBUUID(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
	let rxCharacteristicUUID = CBUUID(string:"6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
	
	
//*******************************************************
// Application Functions
//*******************************************************
	
	// When application loads, start Bluetooth
	override func viewDidLoad() {
		super.viewDidLoad()
		btState = false
		lockStatus = Status.Locked
		startUpCentralManager()
	}

	
	
//*******************************************************
// Central Manager Functions
//*******************************************************

	// Initializes the central manager with a specified delegate.
	func startUpCentralManager() {
		centralManager = CBCentralManager(delegate: self, queue: nil)
	}
	
	// Scans for SmartLocks by searching for advertisements with UART services.
	func discoverDevices() {
		centralManager.scanForPeripheralsWithServices([uartServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
	}
	
	func disconnectDevices() -> Bool {
		if(smartLock != nil) {
			centralManager.cancelPeripheralConnection(smartLock)
			return true
		} else {
			return false
		}
	}
	
	// Invoked when the central manager’s state is updated. (required)
	func centralManagerDidUpdateState(central: CBCentralManager!) { //BLE status
		var msg = ""
		switch (central.state) {
			case .PoweredOff:
				msg = "Bluetooth is off."
			case .PoweredOn:
				msg = "Bluetooth is on and ready."
				discoverDevices()
			case .Resetting:
				var msg = "Bluetooth resetting."
			case .Unauthorized:
				var msg = "Bluetooth unauthorized."
			case .Unknown:
				var msg = "Bluetooth status unknown."
			case .Unsupported:
				var msg = "Bluetooth unsupported."
		}
		
		output("State", data: msg)
	}
	
	// Invoked when the central manager discovers a SmartLock while scanning.
	func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: (NSDictionary), RSSI: NSNumber!) {
		// Conserve battery power by no longer searching for other peripherals
		centralManager.stopScan()
		
		// Get SmartLock peripheral object and its relative signal strength (dBm)
		output("Discovered", data: peripheral.name)
		smartLock = peripheral
		
		// Connect to SmartLock
		centralManager.connectPeripheral(peripheral, options: nil)
	}
	
	// Invoked when a connection is successfully created with a SmartLock.
	func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
		output("Connected", data: peripheral.name)
		btState = true
		
		// Set peripheral delegate so it can receive appropriate callbacks
		// Check peripheral RSSI value
		// Investigate UART Service
		peripheral.delegate = self
		peripheral.readRSSI()
		peripheral.discoverServices([uartServiceUUID])
	}
	
	// Invoked when an existing connection with a SmartLock fails
	func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
		output("Disconnected", data: peripheral.name)
		btState = false
	}
	
	
	
//*******************************************************
// Peripheral (SmartLock) Functions
//*******************************************************
	
	// Invoked when the SmartLock's UART service has been discovered
	func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
		for service in peripheral.services {
			// Investigate UART Service RX and TX Characteristics
			peripheral.discoverCharacteristics([txCharacteristicUUID, rxCharacteristicUUID], forService: service as CBService)
		}
	}
	
	// Invoked when the SmartLock's UART RX and TX characteristics have been discovered
	// Setup notification for RX characteristic
	func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
		for characteristic in service.characteristics as [CBCharacteristic] {
			switch(characteristic.UUID) {
				case rxCharacteristicUUID:
					peripheral.setNotifyValue(true, forCharacteristic: characteristic)
				case txCharacteristicUUID:
					txCharacteristic = characteristic
				default:
					break;
			}
		}
	}
	
	// Invoked when the SmartLock notifies the app that the RX characteristic's value has changed
	func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
		if var data:NSData = characteristic.value {
			var response:String = NSString(data: data, encoding: NSUTF8StringEncoding)!
			switch(response) {
				case "L":
					lockStatus = Status.Locked
					output("Locked")
				case "U":
					lockStatus = Status.Unlocked
					output("Unlocked")
				default:
					output("Received", data: data)
			}
		}
	}
	
	// Lock SmartLock
	func lockSmartLock() {
		let txString = "L"
		let txData = txString.dataUsingEncoding(NSUTF8StringEncoding)
		output("Locking...")
		smartLock.writeValue(txData, forCharacteristic: txCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
	}
	
	// Unlock SmartLock
	func unlockSmartLock() {
		//var txInt = NSInteger(85)
		//let txData = NSData(bytes: &txInt, length:1)
		let txString = "U"
		let txData = txString.dataUsingEncoding(NSUTF8StringEncoding)
		output("Unlocking...")
		smartLock.writeValue(txData, forCharacteristic: txCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
	}
	
	// Update SmartLock RSSI values
	func updateRSSI() {
		if (smartLock != nil) {
			smartLock.readRSSI()
			btRSSI = smartLock.RSSI
			
			if(btRSSI != nil) {
				output("RSSI", data: btRSSI)
			}
		}
	}

	
	
//*******************************************************
// UI Buttons
//*******************************************************
	// If we're connected to SmartLock, send lock command
	// SmartLock interprets 'L' character as lock command
	@IBAction func lockButton() {
		if (btState == true) {
			lockSmartLock()
		} else {
			output("State", data: "SmartLock not connected")
		}
	}
	
	// If we're connected to SmartLock, send unlock command
	// SmartLock interprets 'U' character as unlock command
	@IBAction func unlockButton() {
		if (btState == true) {
			unlockSmartLock()
		} else {
			output("State", data: "SmartLock not connected")
		}
	}

	// If we're connected to SmartLock, get updated RSSI value
	// Otherwise connect to SmartLock
	@IBAction func refreshButton(sender: UIButton) {
		if (btState == true) {
			updateRSSI();
		} else {
			discoverDevices()
		}
	}
	
	// Clear debug log
	@IBAction func clearLog(sender: UIButton) {
		textField.text = "";
	}

	// Disconnect from SmartLock
	@IBAction func disconnectSmartLock(sender: UIButton) {
		if(!disconnectDevices()) {
			output("State", data: "SmartLock not connected")
		}
	}
	
	
	
//*******************************************************
// Debug Functions
//*******************************************************
	func output(description: String) {
		let timestamp = generateTimeStamp()
		println("[\(timestamp)] \(description)")
		textField.text = "[\(timestamp)] \(description)\n" + textField.text
	}
	
	func output(description: String, data: AnyObject) {
		let timestamp = generateTimeStamp()
		println("[\(timestamp)] \(description): \(data)")
		textField.text = "[\(timestamp)] \(description): \(data)\n" + textField.text
	}
	
	func generateTimeStamp() -> NSString {
		let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .NoStyle, timeStyle: .MediumStyle)
		return timestamp
	}
	
}