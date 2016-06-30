//
//  StopWatch.swift
//  BigMT
//
//  Created by Max Tkach on 6/15/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import Foundation
import QuartzCore

class StopWatch: NSObject {
    private var displayLink: CADisplayLink!
    private let formatter = NSDateFormatter()
    
    var callback: (() -> Void)?
    var elapsedTime: CFTimeInterval!
    
    override init() {
        super.init()
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(StopWatch.tick(_:)))
        displayLink.paused = true;
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        self.elapsedTime = 0.0
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.dateFormat = "HH:mm:ss"
    }
    
    convenience init(withCallback callback: () -> Void) {
        self.init()
        self.callback = callback
    }
    
    deinit {
        displayLink.invalidate()
    }
    
    func tick(sender: CADisplayLink) {
        elapsedTime = elapsedTime + displayLink.duration
        callback?()
    }
    
    func start() {
        displayLink.paused = false
    }
    
    func stop() {
        displayLink.paused = true
    }
    
    func reset() {
        displayLink.paused = true
        elapsedTime = 0.0
        callback?()
    }
    
    func elapsedTimeAsString() -> String {
        return formatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate:elapsedTime))
    }
    
    func elapsedTimeAsInt() -> Double {
        return Double(round(100*elapsedTime)/100)
    }
}
