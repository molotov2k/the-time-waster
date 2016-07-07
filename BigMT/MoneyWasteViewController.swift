//
//  MoneyWasteViewController.swift
//  BigMT
//
//  Created by Max Tkach on 6/23/16.
//  Copyright © 2016 Anvil. All rights reserved.
//


import UIKit

class MoneyWasteViewController: UIViewController, UITabBarDelegate {
    
    @IBOutlet weak var currentlyWastedTimeLabel: UILabel!
    
    @IBOutlet weak var userWastedMoneyLabel: UILabel!
    @IBOutlet weak var averageWastedMoneyLabel: UILabel!
    @IBOutlet weak var maxWastedMoneyLabel: UILabel!
    @IBOutlet weak var totalWastedMoneyLabel: UILabel!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        resetIdleTime()
        GlobalStopWatches.currentWastedTimeStopWatch.callback = self.tick
        
        if AppData.userPrivateData["moneyWasted"] < 100 {
            placeholderLabel.hidden = false
            totalWastedMoneyLabel.hidden = true
        } else {
            placeholderLabel.hidden = true
            totalWastedMoneyLabel.hidden = false
        }
        
        let textForUserWasteLabel = Int(AppData.userPrivateData["moneyWasted"]!)
        let textForAverageWastedLabel = Int(AppData.masterGlobalData["averageMoneyWaste"]!)
        let textForMaxWastedLabel = Int(AppData.masterGlobalData["maxMoneyWaste"]!)
        let textForTotalWastedLabel = Int(AppData.masterGlobalData["totalMoneyWaste"]!)
        
        userWastedMoneyLabel.text = "\(textForUserWasteLabel) wm"
        averageWastedMoneyLabel.text = "\(textForAverageWastedLabel) wm"
        maxWastedMoneyLabel.text = "\(textForMaxWastedLabel) wm"
        totalWastedMoneyLabel.text = "\(textForTotalWastedLabel) wm"
        
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
    
    func idleAlert() {
        let alertController = UIAlertController(title: "Achtung!", message: "You have to do something with your phone at least once a minute.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: {action in self.restartStopWatches()}))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
}

