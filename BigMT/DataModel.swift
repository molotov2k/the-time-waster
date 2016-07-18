//
//  DataModel.swift
//  BigMT
//
//  Created by Max Tkach on 6/15/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import Foundation

class DataModel {
    

//# MARK: - User Defaults
    
    func loadUserDefaults() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if !userDefaults.boolForKey("Launched Before") {
            print("DataModel - loadUserDefaults - First time!")
            if !userDefaults.boolForKey("Core Data Record Created") {
                CoreDataHelper().createInitialCoreDataRecord()
                userDefaults.setBool(true, forKey:"Core Data Record Created")
            }
            CloudKitHelper().handleFirstTime()
        } else {
            AppData.userID = userDefaults.valueForKey("UserID") as! String
            print("DataModel - loadUserDefaults - Not the first time!")
        }
    }
    
    
//# MARK: - App Data Values Updates
    
    func updateUserPrivateDataValues() {

        let elapsedTime = GlobalStopWatches.currentWastedTimeStopWatch.elapsedTime

        AppData.userPrivateData["totalWaste"]! += elapsedTime
        AppData.userPrivateData["numberOfWastes"]! += 1
        
        AppData.userPrivateData["averageWasteInUse"] = AppData.userPrivateData["totalWaste"]! / AppData.userPrivateData["numberOfWastes"]!
        
        if elapsedTime > AppData.userPrivateData["maxWasteInUse"] {
            AppData.userPrivateData["maxWasteInUse"] = elapsedTime
        }
        
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        let currentSystemDate = formatter.stringFromDate(NSDate())
        let currentSystemDateAsDouble = Double(currentSystemDate)
        if AppData.userPrivateData["currentDay"] >= currentSystemDateAsDouble {
            AppData.userPrivateData["currentDayWaste"]! += elapsedTime
        } else {
            AppData.userPrivateData["currentDay"] = currentSystemDateAsDouble
            AppData.userPrivateData["numberOfDays"]! += 1
            AppData.userPrivateData["currentDayWaste"] = elapsedTime
        }
        
        AppData.userPrivateData["averageWasteInDay"] = AppData.userPrivateData["totalWaste"]! / AppData.userPrivateData["numberOfDays"]!
        
        if AppData.userPrivateData["maxWasteInDay"] < AppData.userPrivateData["currentDayWaste"]! {
            AppData.userPrivateData["maxWasteInDay"] = AppData.userPrivateData["currentDayWaste"]!
        }

    }
    
    
    func updateMasterGlobalDataValues() {
        
        let elapsedTime = GlobalStopWatches.currentWastedTimeStopWatch.elapsedTime
        
        AppData.masterGlobalData["totalWaste"]! += elapsedTime
        AppData.masterGlobalData["numberOfWastes"]! += 1
        
        AppData.masterGlobalData["averageWasteInUse"] = AppData.masterGlobalData["totalWaste"]! / AppData.masterGlobalData["numberOfWastes"]!
        
        if elapsedTime > AppData.masterGlobalData["maxWasteInUse"] {
            AppData.masterGlobalData["maxWasteInUse"] = elapsedTime
        }
        
        if AppData.masterGlobalData["maxTotalWasteByUser"] < AppData.userPrivateData["totalWaste"] {
            AppData.masterGlobalData["maxTotalWasteByUser"] = AppData.userPrivateData["totalWaste"]
        }

        if AppData.masterGlobalData["maxWasteInDay"] < AppData.userPrivateData["maxWasteInDay"] {
            AppData.masterGlobalData["maxWasteInDay"] = AppData.userPrivateData["maxWasteInDay"]
        }
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        let currentSystemDate = formatter.stringFromDate(NSDate())
        let currentSystemDateAsDouble = Double(currentSystemDate)
        
        if AppData.masterGlobalData["currentDay"] != currentSystemDateAsDouble {
            let timeZoneFormatter = NSDateFormatter()
            timeZoneFormatter.dateFormat = "yyyyMMdd"
            let appCurrentDayAsInt = Int(AppData.masterGlobalData["currentDay"]!)
            let appDate = timeZoneFormatter.dateFromString(String(format: "%lu", appCurrentDayAsInt))
            if let appDate = appDate {
                let timeDifference = NSDate().timeIntervalSinceDate(appDate)
                AppData.masterGlobalData["currentDay"] = currentSystemDateAsDouble
                AppData.masterGlobalData["numberOfDays"]! += Double(Int(timeDifference / 86400))
            } else {
                AppData.masterGlobalData["currentDay"] = currentSystemDateAsDouble
                AppData.masterGlobalData["numberOfDays"]! += 1
            }
        }
        
        if AppData.newUser {
            AppData.masterGlobalData["numberOfUsers"]! += 1
            AppData.newUser = false
        }
        
        AppData.masterGlobalData["averageWasteInDay"] = (AppData.masterGlobalData["totalWaste"]! / AppData.masterGlobalData["numberOfDays"]!) / AppData.masterGlobalData["numberOfUsers"]!
        
    }
    
    
    func updateMasterWastedMoney() {
        
        if AppData.masterGlobalData["maxMoneyWaste"] < AppData.userPrivateData["moneyWasted"] {
            AppData.masterGlobalData["maxMoneyWaste"] = AppData.userPrivateData["moneyWasted"]
        }
        AppData.masterGlobalData["totalMoneyWaste"]! += AppData.thisSessionMoneyWaste
        AppData.masterGlobalData["averageMoneyWaste"] = AppData.masterGlobalData["maxMoneyWaste"]! / AppData.masterGlobalData["numberOfPaidUsers"]!
        
    }
    
    
//# MARK: - User Private Data Conflict Handling
    
    func resolveUserPrivateDataConflict() {
        print("Resolving Conficts")
        
        AppData.userPrivateData["moneyWasted"]! += AppData.tmpData["moneyWasted"]! - AppData.lastSyncedData["moneyWasted"]!
        AppData.userPrivateData["totalWaste"]! += AppData.tmpData["totalWaste"]! - AppData.lastSyncedData["totalWaste"]!
        AppData.userPrivateData["numberOfWastes"]! += AppData.tmpData["numberOfWastes"]! - AppData.lastSyncedData["numberOfWastes"]!
        AppData.userPrivateData["currentDay"] = max(AppData.tmpData["currentDay"]!, AppData.userPrivateData["currentDay"]!)
        if AppData.userPrivateData["currentDay"] == AppData.tmpData["currentDay"] {
            if AppData.userPrivateData["currentDay"] == AppData.lastSyncedData["currentDay"] {
                AppData.userPrivateData["currentDayWaste"]! += AppData.tmpData["currentDayWaste"]! - AppData.lastSyncedData["currentDayWaste"]!
            } else {
                AppData.userPrivateData["currentDayWaste"]! += AppData.tmpData["currentDayWaste"]!
            }
        }
        AppData.userPrivateData["numberOfDays"] = max(AppData.tmpData["numberOfDays"]!, AppData.lastSyncedData["numberOfDays"]!) // Will count wrong in some cases
        AppData.userPrivateData["maxWasteInDay"] = max(AppData.tmpData["maxWasteInDay"]!, AppData.userPrivateData["maxWasteInDay"]!)
        AppData.userPrivateData["maxWasteInUse"] = max(AppData.tmpData["maxWasteInUse"]!, AppData.userPrivateData["maxWasteInUse"]!)
        AppData.userPrivateData["averageWasteInUse"]! = AppData.userPrivateData["totalWaste"]! / AppData.userPrivateData["numberOfWastes"]!
        AppData.userPrivateData["averageWasteInDay"]! = AppData.userPrivateData["totalWaste"]! / AppData.userPrivateData["numberOfDays"]!
        
    }
    
    
}