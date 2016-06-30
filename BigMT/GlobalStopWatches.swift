//
//  GlobalStopWatches.swift
//  BigMT
//
//  Created by Max Tkach on 6/17/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import Foundation

class GlobalStopWatches: NSObject {
    static let currentWastedTimeStopWatch = StopWatch()
    static let idleStopWatch = StopWatch()
    private override init() {}
}