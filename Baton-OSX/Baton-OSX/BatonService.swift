//
//  BatonManager.swift
//  Baton-OSX
//
//  Created by Ben Navetta on 9/3/15.
//  Copyright © 2015 Ben Navetta. All rights reserved.
//

import CoreBluetooth
import Foundation

let BatonServiceUUID = CBUUID(string: "3A9010CF-A241-40C2-9F02-1C30FC74CAB1")

let PointerStateCharacteristicUUID = CBUUID(string: "F1023149-CDC2-46C5-8108-6CF40B0D8185")

protocol BatonServiceDelegate {
    func batonServiceDidPowerOn(service: BatonService)
    func batonService(service: BatonService, peripheralCanConnect peripheral: CBPeripheral) -> Bool
    func batonService(service: BatonService, didConnectToPeripheral peripheral: CBPeripheral)
    func batonService(service: BatonService, encounteredError error: NSError)
    func batonService(service: BatonService, receivedPointerState state: PointerState)
}

extension BatonServiceDelegate {
    func batonServiceDidPowerOn(service: BatonService) {}
    
    func batonService(service: BatonService, peripheralCanConnect peripheral: CBPeripheral) -> Bool {
        return true
    }
    
    func batonService(service: BatonService, didConnectToPeripheral peripheral: CBPeripheral) {}
    
    func batonService(service: BatonService, encounteredError error: NSError) {}
}

class BatonService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let manager: CBCentralManager
    var peripheral: CBPeripheral!
    var delegate: BatonServiceDelegate?
    var stopScanAfterDiscover = true
    
    override init() {
        self.manager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        manager.delegate = self
    }
    
    convenience init(delegate: BatonServiceDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    func startScanning() {
        assert(manager.state == .PoweredOn)
        log.debug("Scanning for peripherals...")
        manager.scanForPeripheralsWithServices([BatonServiceUUID], options: nil)
    }
    
    func stopScanning() {
        log.debug("Ending peripheral scan")
        manager.stopScan()
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if manager.state == .PoweredOn {
            log.debug("Central manager powered on")
            delegate?.batonServiceDidPowerOn(self)
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let name = peripheral.name ?? "Unknown"
        let identifier = peripheral.identifier.UUIDString
        log.debug("Discovered peripheral \(name) - \(identifier)")
        
        let canConnect = delegate?.batonService(self, peripheralCanConnect: peripheral) ?? true
        if canConnect {
            log.info("Connecting to peripheral \(name) - \(identifier)")
            self.peripheral = peripheral
            manager.connectPeripheral(self.peripheral, options: nil)
            
            if stopScanAfterDiscover {
                stopScanning()
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        log.info("Connected to peripheral \(self.peripheral.identifier.UUIDString)")
        
        self.peripheral.delegate = self
        
        delegate?.batonService(self, didConnectToPeripheral: self.peripheral)
        
        self.peripheral.discoverServices([BatonServiceUUID])
//        self.peripheral.discoverServices(nil)
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let error = error {
            delegate?.batonService(self, encounteredError: error)
        }
        else {
            for service in (peripheral.services ?? []).filter({ $0.UUID == BatonServiceUUID }) {
                peripheral.discoverCharacteristics([PointerStateCharacteristicUUID], forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let error = error {
            delegate?.batonService(self, encounteredError: error)
        }
        else {
            for characteristic in service.characteristics ?? [] {
                if characteristic.UUID == PointerStateCharacteristicUUID {
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let error = error {
            delegate?.batonService(self, encounteredError: error)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let error = error {
            delegate?.batonService(self, encounteredError: error)
        }
        else {
            if characteristic.UUID == PointerStateCharacteristicUUID {
                do {
                    if let value = characteristic.value {
                        let state = try PointerState.parseFromData(value)
                        self.delegate?.batonService(self, receivedPointerState: state)
                    }
                }
                catch {
                    delegate?.batonService(self, encounteredError: error as NSError)
                }
            }
        }
    }
}