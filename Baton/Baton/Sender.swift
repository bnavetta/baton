//
//  Sender.swift
//  Baton
//
//  Created by Ben Navetta on 9/3/15.
//  Copyright © 2015 Ben Navetta. All rights reserved.
//

import Foundation
import CoreBluetooth

let serviceUUID = CBUUID(string: "3A9010CF-A241-40C2-9F02-1C30FC74CAB1")

let yawCharacteristicUUID = CBUUID(string: "65DCC176-F25A-41C8-B846-449AD05C0EEB")
let pitchCharacteristicUUID = CBUUID(string: "F1023149-CDC2-46C5-8108-6CF40B0D8185")

class Sender: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    
    var pitchCharacteristic: CBMutableCharacteristic
    var yawCharacteristic: CBMutableCharacteristic
    
    var centralCount = 0
    
    override init() {
        let props = CBCharacteristicProperties(rawValue: CBCharacteristicProperties.Read.rawValue | CBCharacteristicProperties.Indicate.rawValue | CBCharacteristicProperties.Notify.rawValue)
        
        yawCharacteristic = CBMutableCharacteristic(type: yawCharacteristicUUID, properties: props, value: nil, permissions: CBAttributePermissions.Readable)
        pitchCharacteristic = CBMutableCharacteristic(type: pitchCharacteristicUUID, properties: props, value: nil, permissions: CBAttributePermissions.Readable)
        super.init()
    }
    
    func setup() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [yawCharacteristic, pitchCharacteristic]
        peripheralManager.addService(service)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        if let error = error {
            print("Error publishing service: %@", error.localizedDescription)
        }
        else {
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        if request.characteristic.UUID == yawCharacteristicUUID {
            print("Read request for yaw")
            let value = yawCharacteristic.value!
            if request.offset > value.length {
                peripheral.respondToRequest(request, withResult: CBATTError.InvalidOffset)
            }
            else {
                request.value = value.subdataWithRange(NSMakeRange(request.offset, value.length - request.offset))
                peripheral.respondToRequest(request, withResult: CBATTError.Success)
            }
        }
        else if request.characteristic.UUID == pitchCharacteristic.UUID {
            print("Read request for pitch")
            let value = pitchCharacteristic.value!
            if request.offset > value.length {
                peripheral.respondToRequest(request, withResult: CBATTError.InvalidOffset)
            }
            else {
                request.value = value.subdataWithRange(NSMakeRange(request.offset, value.length - request.offset))
                peripheral.respondToRequest(request, withResult: CBATTError.Success)
            }
        }
        else {
            peripheral.respondToRequest(request, withResult: CBATTError.RequestNotSupported)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        print("Central \(central.identifier.UUIDString) subscribed to \(characteristic.UUID.UUIDString)")
        centralCount++
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        print("Central \(central.identifier.UUIDString) unsubscribed from \(characteristic.UUID.UUIDString)")
        centralCount--
    }
    
    func updatePitch(pitch: Double) {
        var rawValue = pitch
        let value = NSData(bytes: &rawValue, length: sizeof(Double))
        
        if centralCount > 0 {
            let status = peripheralManager.updateValue(value, forCharacteristic: pitchCharacteristic, onSubscribedCentrals: nil)
            if status {
//                print("Updated pitch value on peripherals")
            }
            else {
                print("Failed to update pitch value on peripherals")
            }
        }
    }
    
    func updateYaw(yaw: Double) {
        var rawValue = yaw
        let value = NSData(bytes: &rawValue, length: sizeof(Double))
        
        if centralCount > 0 {
            let status = peripheralManager.updateValue(value, forCharacteristic: yawCharacteristic, onSubscribedCentrals: nil)
            if status {
                print("Updated yaw value on peripherals")
            }
            else {
    //            print("Failed to update yaw value on peripherals")
            }
        }
    }
    
    func updateAll(pitch: Double, yaw: Double) {
        var pitchValue: UInt64 = pitch._toBitPattern().bigEndian
        var yawValue: UInt64 = yaw._toBitPattern().bigEndian
        let data = NSMutableData(capacity: 16)!
        data.replaceBytesInRange(NSMakeRange(0, 8), withBytes: &pitchValue)
        data.replaceBytesInRange(NSMakeRange(8, 8), withBytes: &yawValue)
        peripheralManager.updateValue(data, forCharacteristic: pitchCharacteristic, onSubscribedCentrals: nil)
    }
}