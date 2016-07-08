//
//  AppData.swift
//  BigMT
//
//  Created by Max Tkach on 6/20/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import Foundation

class AppData: NSObject {
    
    static var userID = ""
    static var newUser = false
    
    static var lastSyncedData = [String: Double]()
    static var tmpData = [String: Double]() // only exists when resolving user private data confict
    
    static var inAppPurchaseIDs = [String: Double]()
    static var buyingFirstTime = false
    static var thisSessionMoneyWaste = 0.0
    
    static var lastUserPrivateDataUpdateTime = NSDate()
    static var lastMasterGlobalDataUpdateTime = NSDate()
    
    static var userPrivateUpdateID = 0.0
    
    static var userPrivateData = ["averageWasteInDay": 0.0,
                                  "averageWasteInUse": 0.0,
                                  "maxWasteInDay": 0.0,
                                  "maxWasteInUse": 0.0,
                                  "numberOfWastes": 0.0,
                                  "totalWaste": 0.0,
                                  "numberOfDays": 0.0,
                                  "currentDayWaste": 0.0,
                                  "currentDay": 0.0,
                                  "updateID": 0.0,
                                  "moneyWasted": 0.0 ]
    
    static var masterGlobalData = ["averageWasteInDay": 0.0,
                                   "averageWasteInUse": 0.0,
                                   "averageMoneyWaste": 0.0,
                                   "maxWasteInDay": 0.0,
                                   "maxWasteInUse": 0.0,
                                   "maxMoneyWaste": 0.0,
                                   "numberOfWastes": 0.0,
                                   "totalWaste": 0.0,
                                   "maxTotalWasteByUser": 0.0,
                                   "numberOfDays": 0.0,
                                   "currentDay": 0.0,
                                   "numberOfUsers": 1.0,
                                   "numberOfPaidUsers": 0.0,
                                   "totalMoneyWaste": 0.0,
                                   "updateID": 0.0 ]
    
    private override init() {}
    
}