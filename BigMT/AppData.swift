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
    
    static var lastUserPrivateDataUpdateTime = NSDate()
    static var lastMasterGlobalDataUpdateTime = NSDate()
    
    static var inAppPurchaseIDs = [String]()
    
    static var userPrivateData = ["averageWasteInDay": 0.0,
                                  "averageWasteInUse": 0.0,
                                  "maxWasteInDay": 0.0,
                                  "maxWasteInUse": 0.0,
                                  "numberOfWastes": 0.0,
                                  "totalWaste": 0.0,
                                  "numberOfDays": 0.0,
                                  "currentDayWaste": 0.0,
                                  "currentDay": 0.0,
                                  "updateID": 0.0]
    
    static var masterGlobalData = ["averageWasteInDay": 0.0,
                                   "averageWasteInUse": 0.0,
                                   "maxWasteInDay": 0.0,
                                   "maxWasteInUse": 0.0,
                                   "numberOfWastes": 0.0,
                                   "totalWaste": 0.0,
                                   "maxTotalWasteByUser": 0.0,
                                   "numberOfDays": 0.0,
                                   "currentDay": 0.0,
                                   "numberOfUsers": 0.0,
                                   "updateID": 0.0]
    
    private override init() {}
    
}