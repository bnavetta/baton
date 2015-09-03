//
//  ViewController.swift
//  Baton
//
//  Created by Ben Navetta on 9/3/15.
//  Copyright © 2015 Ben Navetta. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

extension Double {
    var rad2deg: Double {
        return self * 180.0 / M_PI
    }
}

private let numberFormatter: NSNumberFormatter = {
    var formatter = NSNumberFormatter()
    formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
    return formatter
    }()

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet
    weak var pitchLabel: UILabel!
    
    @IBOutlet
    weak var rollLabel: UILabel!
    
    @IBOutlet
    weak var yawLabel: UILabel!
    
    @IBOutlet
    weak var coordinateLabel: UILabel!
    
    @IBOutlet
    weak var altitudeLabel: UILabel!
    
    let sender: Sender = {
        var sender = Sender()
        sender.setup()
        return sender
    }()
    
    let motionManager = CMMotionManager()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
                [weak self] (data: CMDeviceMotion?, error: NSError?) in
                
                if let data = data {
                    let attitude = data.attitude
                    
                    let pitch = numberFormatter.stringFromNumber(attitude.pitch.rad2deg) ?? "?"
                    self?.pitchLabel.text = "\(pitch)˚"
                    
                    let roll = numberFormatter.stringFromNumber(attitude.roll.rad2deg) ?? "?"
                    self?.rollLabel.text = "\(roll)˚"
                    
                    
                    let yaw = numberFormatter.stringFromNumber(attitude.yaw.rad2deg) ?? "?"
                    self?.yawLabel.text = "\(yaw)˚"
                    
//                    self?.sender.updatePitch(attitude.pitch.rad2deg)
//                    self?.sender.updateYaw(attitude.yaw.rad2deg)
                    self?.sender.updateAll(attitude.pitch, yaw: attitude.yaw)
                    
                }
                else {
                     self?.pitchLabel.text = "Unknown"
                }
            }
        }
        else {
            print("Device Motion not available")
        }
        
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
//        if manager.gyroAvailable {
//            manager.gyroUpdateInterval = 0.1
//            manager.startGyroUpdatesToQueue(NSOperationQueue.mainQueue()) {
//                [weak self] (data: CMGyroData?, error: NSError?) in
//                
//                if let error = error {
//                    print("Error accessing gyroscope: \(error)")
//                }
//                else {
//                    self?.pitchLabel.text = data.
//                }
//            }
//        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let eventDate = location.timestamp
            let howRecent = eventDate.timeIntervalSinceNow
            if abs(howRecent) < 15.0 {
                // Only use recent events
                let latitude = numberFormatter.stringFromNumber(location.coordinate.latitude) ?? "?"
                let longitude = numberFormatter.stringFromNumber(location.coordinate.longitude) ?? "?"
                let altitude = numberFormatter.stringFromNumber(location.altitude) ?? "?"
                
                self.coordinateLabel.text = "(\(latitude), \(longitude))"
                self.altitudeLabel.text = altitude
//                self.locationManager.stopUpdatingLocation()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

