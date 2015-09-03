//
//  AppDelegate.swift
//  Baton-OSX
//
//  Created by Ben Navetta on 9/3/15.
//  Copyright © 2015 Ben Navetta. All rights reserved.
//

import Cocoa
import CoreBluetooth
import ApplicationServices

let serviceUUID = CBUUID(string: "3A9010CF-A241-40C2-9F02-1C30FC74CAB1")

let yawCharacteristicUUID = CBUUID(string: "65DCC176-F25A-41C8-B846-449AD05C0EEB")
let pitchCharacteristicUUID = CBUUID(string: "F1023149-CDC2-46C5-8108-6CF40B0D8185")

extension Double {
    var rad2deg: Double {
        return self * 180.0 / M_PI
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var manager: CBCentralManager!
    var peripheral: CBPeripheral!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            central.scanForPeripheralsWithServices([serviceUUID], options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        self.peripheral = peripheral
        print("Found peripheral: \(self.peripheral.name) - \(self.peripheral.identifier.UUIDString)")
        manager.connectPeripheral(self.peripheral, options: nil)
        manager.stopScan()
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connected to \(self.peripheral.name) - \(self.peripheral.identifier.UUIDString)")
        self.peripheral.delegate = self
//        peripheral.discoverServices([serviceUUID])
        self.peripheral.discoverServices(nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for service in peripheral.services ?? [] {
            print("Discovered service for \(self.peripheral.name): \(service)")
            
            self.peripheral.discoverCharacteristics([yawCharacteristicUUID, pitchCharacteristicUUID], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for characteristic in service.characteristics ?? [] {
            print("Discovered characteristic \(characteristic.UUID.UUIDString) for service \(service.UUID.UUIDString) on \(peripheral.name)")
            
            if characteristic.UUID == yawCharacteristicUUID || characteristic.UUID == pitchCharacteristicUUID {
                print("Subscribing to characteristic \(characteristic.UUID.UUIDString)")
                self.peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        if let error = error {
            print("Error subscribing to characteristic \(characteristic.UUID.UUIDString): \(error.localizedDescription)")
        }
        else {
            print("Subscribed to characteristic \(characteristic.UUID.UUIDString) on \(peripheral.name)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        if let error = error {
            print("Error reading \(characteristic.UUID.UUIDString): \(error.localizedDescription)")
        }
        
        if characteristic.UUID == yawCharacteristicUUID {
            var yaw: Double = 0
            characteristic.value?.getBytes(&yaw, length: sizeof(Double))
            print("Yaw: \(yaw)")
        }
        else if characteristic.UUID == pitchCharacteristicUUID {
            var rawPitch: UInt64 = 0
            characteristic.value?.getBytes(&rawPitch, length: 8)
            let pitch = Double._fromBitPattern(UInt64(bigEndian: rawPitch))
            
            var rawYaw: UInt64 = 0
            characteristic.value?.getBytes(&rawYaw, range: NSMakeRange(8, 8))
            let yaw = Double._fromBitPattern(UInt64(bigEndian: rawYaw))
            
//            print("Pitch: \(pitch), yaw: \(yaw)")
            
            let screen = NSScreen.mainScreen()!.frame
            
            let x = clamp(CGFloat(tan(-yaw)) * (screen.width / 4) + screen.width / 2, min: 0, max: screen.width)
            let y = clamp(CGFloat(tan(-pitch)) * (screen.height / 4) + screen.height / 2, min: 0, max: screen.height)
            
            print("pitch \(pitch.rad2deg) and yaw \(yaw.rad2deg) -> (\(x), \(y))")
            
            let event = CGEventCreateMouseEvent(nil, CGEventType.MouseMoved, CGPointMake(x, y), CGMouseButton.Left)
            CGEventPost(CGEventTapLocation.CGHIDEventTap, event)
        }
    }
}

func clamp<F: Comparable>(val: F, min: F, max: F) -> F {
    if val < min {
        return min
    }
    else if val > max {
        return max
    }
    else {
        return val
    }
}

