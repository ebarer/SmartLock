//
//  SmartLock.swift
//  SmartLock
//
//  Created by Elliot Barer on 2014-12-03.
//  Copyright (c) 2014 Elliot Barer. All rights reserved.
//

import UIKit
import CoreBluetooth

enum Status {
	case Locking
	case Locked
	case Unlocking
	case Unlocked
	case Unknown
}

class SmartLock: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

	// Prevent multiple instances of SmartLock from being created
	class var sharedInstance:SmartLock {
		struct Static {
			static let instance:SmartLock = SmartLock()
		}
		
		return Static.instance
	}
	
	
	
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
	
	var centralManager:CBCentralManager!				// Bluetooth central manager (iOS Device)
	var smartLock:CBPeripheral!							// Bluetooth peripheral device (SmartLock)
	var rxCharacteristic:CBCharacteristic!				// Bluetooth RX characteristic
	var txCharacteristic:CBCharacteristic!				// Bluetooth TX characteristic
	
	var bluetoothState:Bool!							// Bluetooth status
	var connectTimer:NSTimer!							// Connection timeout timer
	var connectState:Bool!
	var lockStatus:Status!								// Lock status
	dynamic var activity:String!						// Lock activity
	dynamic var debugActivity:String!					// Lock activity (debug)
	
	// Signal strength (RSSI) in dBm
	var proximityEnable:Bool!							// Proximity detection status
	var rssiTimer:NSTimer!								// RSSI update timer
	var rssiNow:Int!									// Current RSSI value
	var rssiOld = [Int](count: 3, repeatedValue: 0)		// Previous RSSI values
	var lockThreshold = -73								// Locking RSSI threshold
	var unlockThreshold = -67							// Unlocking RSSI threshold
	
	// UUIDs for SmartLock UART Service and Characteristics (RX/TX)
	var smartLockNSUUID:NSUUID!
	let uartServiceUUID = CBUUID(string:"6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
	let txCharacteristicUUID = CBUUID(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
	let rxCharacteristicUUID = CBUUID(string:"6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
	
	override init() {
		super.init()
		
		bluetoothState = false
		connectState = false
		lockStatus = .Locked
		proximityEnable = false
		rssiNow = 0
	}
	
	
	
//*******************************************************
// Central Manager Functions
//*******************************************************
	
	// Initializes the central manager with a specified delegate.
	func startUpCentralManager() {
		centralManager = CBCentralManager(delegate: self, queue: nil)
	}
	
	// Connect to SmarLock
	func connectToSmartLock(peripheral: CBPeripheral) {
		centralManager.connectPeripheral(peripheral as CBPeripheral, options: [CBConnectPeripheralOptionNotifyOnNotificationKey: true])
	}
	
	// Disconnect from SmartLock
	func disconnectFromSmartLock() {
		if(smartLock != nil) {
			centralManager.cancelPeripheralConnection(smartLock)
			smartLock = nil
		}
	}
	
	// Invoked when the central manager’s state is updated.
	func centralManagerDidUpdateState(central: CBCentralManager!) {
		switch (central.state) {
		case .PoweredOff:
			bluetoothState = false
			output("Bluetooth Off")
			disconnectFromSmartLock()
		case .PoweredOn:
			bluetoothState = true
			output("Bluetooth On")
			discoverDevices()
		default:
			bluetoothState = false
			output("Bluetooth Unknown")
		}
	}
	
	// Scans for SmartLocks by searching for advertisements with UART services.
	func discoverDevices() {
		// Avoid scanning by reconnecting to known good SmartLock
		// If not found, scan for other devices
		if (bluetoothState == true) {
			output("Searching...", UI: true)
			
			if (smartLockNSUUID != nil) {
				var peripherals = centralManager.retrievePeripheralsWithIdentifiers([smartLockNSUUID!])
				for peripheral in peripherals {
					smartLock = peripheral as CBPeripheral
					connectToSmartLock(peripheral as CBPeripheral)
				}
			} else {
				centralManager.scanForPeripheralsWithServices([uartServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
			}
		}
	}
	
	// Invoked when the central manager discovers a SmartLock while scanning.
	func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: (NSDictionary), RSSI: NSNumber!) {
		// Conserve battery
		centralManager.stopScan()
		
		// Connect to SmartLock
		output("Discovered", UI: true)
		smartLock = peripheral
		smartLockNSUUID = peripheral.identifier
		connectTimer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: Selector("cancelConnect"), userInfo: nil, repeats: false)
		connectToSmartLock(peripheral)
	}
	
	// Invoked when a connection is successfully created with a SmartLock.
	func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
		// Set peripheral delegate so it can receive appropriate callbacks
		// Check peripheral RSSI value
		// Investigate UART Service
		connectState = true
		connectTimer.invalidate()
		output("Connected", UI: true)
		
		peripheral.delegate = self
		peripheral.readRSSI()
		peripheral.discoverServices([uartServiceUUID])
	}
	
	// Invoked when an existing connection with a SmartLock fails
	func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
		connectState = false
		output("Disconnected", UI: true)
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
				rxCharacteristic = characteristic
				smartLock.readValueForCharacteristic(rxCharacteristic)
				peripheral.setNotifyValue(true, forCharacteristic: rxCharacteristic)
			case txCharacteristicUUID:
				txCharacteristic = characteristic
			default:
				break
			}
		}
	}

	// Invoked when the SmartLock receives a request to start or stop providing notifications for a specified characteristic’s value.
	func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
		if (error != nil) {
			output("Error: \(error.localizedDescription)")
		}
	}
	
	// Invoked when the SmartLock notifies the app that the RX characteristic's value has changed
	func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
		if var data:NSData = characteristic.value {
			var response:String = NSString(data: data, encoding: NSUTF8StringEncoding)!
			switch(response) {
			case "L":
				lockStatus = .Locked
				output("Locked", UI: true)
			case "U":
				lockStatus = .Unlocked
				output("Unlocked", UI: true)
			default:
				lockStatus = .Unknown
				output("Bad Data: \(data)")
			}
		}
	}
	
	// Cancel connection
	func cancelConnect() {
		connectTimer.invalidate()
		output("Connection timeout", UI: true)
		disconnectFromSmartLock()
	}

	// Determine lock status
	func getConnectionState() -> Bool {
		if (smartLock != nil) {
			if (smartLock.state == CBPeripheralState.Connected) {
				connectState = true
				return true
			} else {
				discoverDevices()
				connectState = false
				return false
			}
		} else {
			connectState = false
			return false
		}
	}
	
	// Lock SmartLock
	func lockSmartLock() {
		if(getConnectionState() == true) {
			if(lockStatus == .Unlocked) {
				let txString = "L"
				let txData = txString.dataUsingEncoding(NSUTF8StringEncoding)
				lockStatus = Status.Locking
				output("Locking...", UI: true)
				smartLock.writeValue(txData, forCharacteristic: txCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
			}
		}
	}
	
	// Unlock SmartLock
	func unlockSmartLock() {
		if(getConnectionState() == true) {
			if(lockStatus == .Locked) {
				let txString = "U"
				let txData = txString.dataUsingEncoding(NSUTF8StringEncoding)
				lockStatus = Status.Unlocking
				output("Unlocking...", UI: true)
				smartLock.writeValue(txData, forCharacteristic: txCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
			}
		}
	}
	
	// Enable the RSSI timer for proximity mode
	func rssiTimerEnable() {
		// Initialize a timer to check RSSI value every 0.5 seconds while connected
		rssiTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("updateRSSI"), userInfo: nil, repeats: true)
		proximityEnable = true
	}

	// Disable the RSSI timer
	func rssiTimerDisable() {
		if (rssiTimer != nil) {
			rssiTimer.invalidate()
			proximityEnable = false
		}
	}

	// Proximity detection
	func updateRSSI() {
		var rssiAverage:Int
		
		if (smartLock != nil && getConnectionState() == true) {
			smartLock.readRSSI()
			if(smartLock.RSSI != nil) {
				// Take 4 values for accurate average of RSSI value
				rssiOld[2] = rssiOld[1]
				rssiOld[1] = rssiOld[0]
				rssiOld[0] = rssiNow
				rssiNow = Int(smartLock.RSSI)
				rssiAverage = ((rssiNow + rssiOld[0] + rssiOld[1] + rssiOld[2])/4)
				
				// Output proximity equation
				if (lockStatus == .Locked) {
					output("RSSI: \(rssiAverage) > \(unlockThreshold) = \(rssiAverage > unlockThreshold)")
				} else {
					output("RSSI: \(rssiAverage) < \(lockThreshold) = \(rssiAverage < lockThreshold)")
				}

				// If locked, within range, and moving toward lock: unlock
				if ((lockStatus == .Locked) && (rssiAverage > unlockThreshold)) {
					unlockSmartLock()
				}

				// If unlocked, leaving range, and moving away from lock: lock
				if ((lockStatus == .Unlocked) && (rssiAverage < lockThreshold)) {
					lockSmartLock()
				}
			}
		}
	}
	
	
	
//*******************************************************
// Debug Functions
//*******************************************************
	
	func output(description: String, UI: Bool = false) {
		let timestamp = generateTimeStamp()

		if (UI.boolValue == true) {
			activity = "\(description)"
		}
		
		println("[\(timestamp)] \(description)")
		debugActivity = "\(description)"
	}
	
	func generateTimeStamp() -> NSString {
		let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .NoStyle, timeStyle: .MediumStyle)
		return timestamp
	}
	
}