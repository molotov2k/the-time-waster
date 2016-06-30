//
//  GlobalStatsViewController.swift
//  BigMT
//
//  Created by Max Tkach on 6/22/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import UIKit

class GlobalStatsViewController: UIViewController, UITabBarDelegate {
    
    @IBOutlet weak var currentlyWastedTimeLabel: UILabel!
    @IBOutlet weak var averageWastedTimeInUseLabel: UILabel!
    @IBOutlet weak var averageWastedTimeInDayLabel: UILabel!
    @IBOutlet weak var maxWastedTimeInUseLabel: UILabel!
    @IBOutlet weak var maxWastedTimeInDayLabel: UILabel!
    @IBOutlet weak var maxTotalWastedTimeByUserLabel: UILabel!
    @IBOutlet weak var totalWastedTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        resetIdleTime()
        GlobalStopWatches.currentWastedTimeStopWatch.callback = self.tick
        averageWastedTimeInUseLabel.text = formatElapsedTime(AppData.masterGlobalData["averageWasteInUse"]!)
        averageWastedTimeInDayLabel.text = formatElapsedTime(AppData.masterGlobalData["averageWasteInDay"]!)
        maxWastedTimeInUseLabel.text = formatElapsedTime(AppData.masterGlobalData["maxWasteInUse"]!)
        maxWastedTimeInDayLabel.text = formatElapsedTime(AppData.masterGlobalData["maxWasteInDay"]!)
        totalWastedTimeLabel.text = formatElapsedTime(AppData.masterGlobalData["totalWaste"]!)
        maxTotalWastedTimeByUserLabel.text = formatElapsedTime(AppData.masterGlobalData["maxTotalWasteByUser"]!)
    }
    
    func tick() {
        currentlyWastedTimeLabel.text = GlobalStopWatches.currentWastedTimeStopWatch.elapsedTimeAsString()
        if (GlobalStopWatches.idleStopWatch.elapsedTime > 60) {
            GlobalStopWatches.currentWastedTimeStopWatch.stop()
            GlobalStopWatches.idleStopWatch.reset()
            idleAlert()
        }
    }
    
    func restartStopWatches() {
        GlobalStopWatches.currentWastedTimeStopWatch.start()
        GlobalStopWatches.idleStopWatch.start()
    }
    
    func resetIdleTime() {
        GlobalStopWatches.idleStopWatch.elapsedTime = 0.0
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        resetIdleTime()
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        resetIdleTime()
    }
    
    func formatElapsedTime(value:Double) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "HH : mm : ss"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return formatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate:value))
    }
    
    func idleAlert() {
        let alertController = UIAlertController(title: "Achtung!", message: "You have to do something with your phone at least once a minute.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: {action in self.restartStopWatches()}))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
}