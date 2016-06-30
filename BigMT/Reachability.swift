//
//  Reachability.swift
//  BigMT
//
//  Created by Max Tkach on 6/27/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import SystemConfiguration
import UIKit

public class Reachability {

    
    func trackConnectionStatus() {
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let reachability = SCNetworkReachabilityCreateWithName(nil, "apple.com")!
        
        SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            //print(flags)
            appDelegate.internetConnectionAvailable = flags.rawValue > 0
            }, &context)
        
        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes)
    }
    
    
}