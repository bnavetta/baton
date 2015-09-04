//
//  BatonPeripheral.swift
//  Baton
//
//  Created by Ben Navetta on 9/3/15.
//  Copyright © 2015 Ben Navetta. All rights reserved.
//

import CoreBluetooth
import Foundation

let BatonServiceUUID = CBUUID(string: "3A9010CF-A241-40C2-9F02-1C30FC74CAB1")

let PointerStateCharacteristicUUID = CBUUID(string: "F1023149-CDC2-46C5-8108-6CF40B0D8185")

protocol BatonPeripheralDelegate {
    func batonPeripheral(peripheral: BatonPeripheral, encounteredError error: NSError)
    func batonPeripheralIsReady(peripheral: BatonPeripheral)
}

class BatonPeripheral: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    var delegate: BatonPeripheralDelegate?
    var isReady = false
    
    let pointerStateCharacteristic = CBMutableCharacteristic(
        type: PointerStateCharacteristicUUID,
        properties: CBCharacteristicProperties(rawValue: CBCharacteristicProperties.Read.rawValue | CBCharacteristicProperties.NotifyEncryptionRequired.rawValue),
        value: nil, permissions: CBAttributePermissions.ReadEncryptionRequired)
    
    override init() {
        peripheralManager = CBPeripheralManager(delegate: nil, queue: nil)
        super.init()
        peripheralManager.delegate = self
    }
    
    func start() {
        assert(isReady)
        log.debug("Advertising BatonService")
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [BatonServiceUUID]])
    }
    
    func stop() {
        log.debug("Will stop advertising")
        peripheralManager.stopAdvertising()
    }
    
    func updatePointerState(state: PointerState) {
//        log.debug("Updating PointerState characteristic")
        peripheralManager.updateValue(state.data(), forCharacteristic: pointerStateCharacteristic, onSubscribedCentrals: nil)
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if peripheral.state == CBPeripheralManagerState.PoweredOn {
            log.debug("Adding BatonService")
            let service = CBMutableService(type: BatonServiceUUID, primary: true)
            service.characteristics = [pointerStateCharacteristic]
            peripheral.addService(service)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        if let error = error {
            delegate?.batonPeripheral(self, encounteredError: error)
        }
        else {
            log.info("Added BatonService")
            isReady = true
            delegate?.batonPeripheralIsReady(self)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        if request.characteristic.UUID == PointerStateCharacteristicUUID {
            log.debug("Handling read request for PointerState characteristic")
            if let value = pointerStateCharacteristic.value {
                if request.offset > value.length {
                    peripheral.respondToRequest(request, withResult: CBATTError.InvalidOffset)
                }
                else {
                    request.value = value.subdataWithRange(NSMakeRange(request.offset, value.length - request.offset))
                    peripheral.respondToRequest(request, withResult: CBATTError.Success)
                }
            }
            else {
                peripheral.respondToRequest(request, withResult: CBATTError.InvalidAttributeValueLength)
            }
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        log.debug("Central \(central.identifier.UUIDString) subscribed to \(characteristic.UUID.UUIDString)")
    }
}