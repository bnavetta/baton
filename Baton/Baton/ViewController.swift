//
//  ViewController.swift
//  Baton
//
//  Created by Ben Navetta on 9/3/15.
//  Copyright © 2015 Ben Navetta. All rights reserved.
//

import UIKit

private extension Double {
    var rad2deg: Double {
        return self * 180.0 / M_PI
    }
}

private let numberFormatter: NSNumberFormatter = {
    var formatter = NSNumberFormatter()
    formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
    return formatter
    }()

class ViewController: UIViewController, PointerServiceDelegate, BatonPeripheralDelegate {
    
    let pointerService = PointerService()
    let peripheral = BatonPeripheral()
    
    @IBOutlet
    weak var pitchLabel: UILabel!
    
    @IBOutlet
    weak var yawLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        pointerService.delegate = self
        peripheral.delegate = self
        pointerService.start()
    }
    
    deinit {
        pointerService.stop()
        peripheral.stop()
    }
    
    func presentError(error: NSError, title: String, defaultFailureReason: String) {
        let failureReason = error.localizedFailureReason ?? defaultFailureReason
        let message = "\(error.localizedDescription). \(failureReason)"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {_ in})
        alert.addAction(defaultAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: PointerServiceDelegate
    
    func onStateChange(state: PointerState) {
        let pitch = numberFormatter.stringFromNumber(state.pitch.rad2deg) ?? "?"
        let yaw = numberFormatter.stringFromNumber(state.yaw.rad2deg) ?? "?"
        pitchLabel.text = "\(pitch)˚"
        yawLabel.text = "\(yaw)˚"
        
        peripheral.updatePointerState(state)
    }
    
    func onError(error: NSError) {
        presentError(error, title: "Motion Error", defaultFailureReason: "Unable to determine pointer state from device motion")
    }
    
    // MARK: BatonPeripheralDelegate
    
    func batonPeripheral(peripheral: BatonPeripheral, encounteredError error: NSError) {
        presentError(error, title: "Bluetooth Error", defaultFailureReason: "Unable to publish data")
    }
    
    func batonPeripheralIsReady(peripheral: BatonPeripheral) {
        peripheral.start()
    }
}

