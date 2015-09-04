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

import XCGLogger

extension Double {
    var rad2deg: Double {
        return self * 180.0 / M_PI
    }
}

let log = XCGLogger.defaultInstance()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, BatonServiceDelegate {

    @IBOutlet weak var window: NSWindow!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    
    var baton: BatonService!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        baton = BatonService(delegate: self)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "BatonStatusBarButtonImage")
            button.action = "onStatusItemClicked:"
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func onStatusItemClicked(sender: AnyObject) {
        print("Clicked!")
    }
    
    // MARK: BatonServiceDelegate
    
    func batonService(service: BatonService, encounteredError error: NSError) {
        print("Baton Service Error: \(error.localizedDescription)")
    }
    
    func batonService(service: BatonService, receivedPointerState state: PointerState) {
        let screen = NSScreen.mainScreen()!.frame
        let pitch = state.pitch
        let yaw = state.yaw
        
        let x = clamp(CGFloat(tan(-yaw)) * (screen.width / 4) + screen.width / 2, min: 0, max: screen.width)
        let y = clamp(CGFloat(tan(-pitch)) * (screen.height / 4) + screen.height / 2, min: 0, max: screen.height)
        
//        print("pitch \(pitch.rad2deg) and yaw \(yaw.rad2deg) -> (\(x), \(y))")
        
        let event = CGEventCreateMouseEvent(nil, CGEventType.MouseMoved, CGPointMake(x, y), CGMouseButton.Left)
        CGEventPost(CGEventTapLocation.CGHIDEventTap, event)
    }
    
    func batonServiceDidPowerOn(service: BatonService) {
        baton.startScanning()
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

