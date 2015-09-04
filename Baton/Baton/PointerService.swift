//
//  Service.swift
//  Baton
//
//  Created by Ben Navetta on 9/3/15.
//  Copyright © 2015 Ben Navetta. All rights reserved.
//

import CoreMotion
import Foundation

protocol PointerServiceDelegate {
    func onError(error: NSError)
    func onStateChange(state: PointerState)
}

class PointerService {
    let motionManager = CMMotionManager()
    
    var delegate: PointerServiceDelegate?
    
    func start() -> Bool {
        if motionManager.deviceMotionAvailable {
            if !motionManager.deviceMotionActive {
                motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
                    [weak self] (motion: CMDeviceMotion?, error: NSError?) in
                    
                    if let error = error {
                        self?.delegate?.onError(error)
                    }
                    else if let motion = motion {
                        let state = try! PointerState.Builder()
                            .setPitch(motion.attitude.pitch)
                            .setYaw(motion.attitude.yaw)
                            .build()
                        self?.delegate?.onStateChange(state)
                    }
                }
            }
            return true
        }
        else {
            log.error("Device Motion not supported")
            return false
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}