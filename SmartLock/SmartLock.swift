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
	case Locked
	case Unlocked
	case None
}

class SmartLock: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
	
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
	var rxCharacteristic:CBCharacteristic!			// Bluetooth RX characteristic
	var txCharacteristic:CBCharacteristic!			// Bluetooth TX characteristic
	
	var bluetoothState:Bool!						// Bluetooth status
	var connectState:Bool!							// Connection status
	var lockStatus:Status!							// Lock status
	var activity:String!							// Lock activity
	
	// Signal strength (RSSI) in dBm
	var rssiNow:Int!								// Current RSSI value
	var rssiTimer:NSTimer!							// RSSI update timer
	
	// UUIDs for SmartLock UART Service and Characteristics (RX/TX)
	let uartServiceUUID = CBUUID(string:"6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
	let txCharacteristicUUID = CBUUID(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
	let rxCharacteristicUUID = CBUUID(string:"6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
	
	override init() {
		super.init()
		
		bluetoothState = false
		connectState = false
		lockStatus = Status.Locked
		
		// Initialize a timer to check RSSI value every 1.5 seconds while connected
		rssiTimer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: Selector("updateRSSI"), userInfo: nil, repeats: true)
		rssiNow = 0
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
		centralManager.retrievePeripheralsWithIdentifiers(smartLock)
		
		centralManager.scanForPeripheralsWithServices([uartServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
		output("Scanning...")
	}
	
	func disconnectDevices() {
		if(connectState == true) {
			centralManager.cancelPeripheralConnection(smartLock)
		}
	}
	
	// Invoked when the central manager’s state is updated. (required)
	func centralManagerDidUpdateState(central: CBCentralManager!) { //BLE status
		var msg = ""
		switch (central.state) {
		case .PoweredOff:
			output("Bluetooth Off")
			bluetoothState = false
		case .PoweredOn:
			output("Bluetooth On")
			bluetoothState = true
			discoverDevices()
		default:
			output("Bluetooth Unknown")
		}
	}
	
	// Invoked when the central manager discovers a SmartLock while scanning.
	func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: (NSDictionary), RSSI: NSNumber!) {
		// Conserve battery
		centralManager.stopScan()
		
		// Connect to SmartLock
		output("Discovered")
		smartLock = peripheral
		centralManager.connectPeripheral(peripheral, options: nil)
	}
	
	// Invoked when a connection is successfully created with a SmartLock.
	func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
		// Set peripheral delegate so it can receive appropriate callbacks
		// Check peripheral RSSI value
		// Investigate UART Service
		connectState = true
		output("Connected")
		
		peripheral.delegate = self
		peripheral.readRSSI()
		peripheral.discoverServices([uartServiceUUID])
	}
	
	// Invoked when an existing connection with a SmartLock fails
	func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
		connectState = false
		output("Disconnected")
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
				rxCharacteristic = characteristic
			case txCharacteristicUUID:
				txCharacteristic = characteristic
			default:
				break
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
				output("Bad Data: \(data)")
			}
		}
	}
	
	// Lock SmartLock
	func lockSmartLock() {
		if(connectState == true) {
			if(lockStatus == Status.Unlocked) {
				let txString = "L"
				let txData = txString.dataUsingEncoding(NSUTF8StringEncoding)
				smartLock.writeValue(txData, forCharacteristic: txCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
				output("Locking...")
			}
		}
	}
	
	// Unlock SmartLock
	func unlockSmartLock() {
		if(connectState == true) {
			if(lockStatus == Status.Locked) {
				let txString = "U"
				let txData = txString.dataUsingEncoding(NSUTF8StringEncoding)
				smartLock.writeValue(txData, forCharacteristic: txCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
				output("Unlocking...")
			}
		}
	}

	// Proximity detection
	func updateRSSI() {
		let threshold = -75
		let distance = 0
		var rssiOld = 0
		
		if (smartLock != nil && connectState == true) {
			smartLock.readRSSI()
			if(smartLock.RSSI != nil) {
				rssiOld = rssiNow
				rssiNow = Int(smartLock.RSSI)
				distance = 10 * pow(<#Double#>, <#Double#>)
				output("RSSI: \(rssiNow)[now], \(rssiOld)[old]")
				smartLock.readValueForCharacteristic(rxCharacteristic)

				// If locked, within range, and moving toward lock: unlock
				if ((lockStatus == Status.Locked) && (rssiNow >= threshold) && (rssiNow >= threshold)) {
					unlockSmartLock()
				}

				// If unlocked, leaving range, and moving away from lock: lock
				if ((lockStatus == Status.Unlocked) && (rssiNow < threshold) && (rssiOld < threshold)) {
					lockSmartLock()
				}
			}
		} else {
			discoverDevices()
		}
	}
	
	
	
//*******************************************************
// Debug Functions
//*******************************************************
	
	func output(description: String) {
		let timestamp = generateTimeStamp()
		println("[\(timestamp)] \(description)")
		activity = "[\(timestamp)] \(description)"
	}
	
	func generateTimeStamp() -> NSString {
		let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .NoStyle, timeStyle: .MediumStyle)
		return timestamp
	}
	
}