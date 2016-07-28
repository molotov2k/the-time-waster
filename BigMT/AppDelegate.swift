//
//  AppDelegate.swift
//  BigMT
//
//  Created by Max Tkach on 6/15/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var saved = false
    var savedInCloud = false
    var shouldLoad = false
    var appIsActive = false
    var notificationsEnabled = false
    var updatingCloudUserData = false
    var updatingCloudMasterData = false
    var cloudUpdatesInProgress: Bool {
        get { return updatingCloudMasterData || updatingCloudUserData }
    }
    
    var internetConnectionAvailable = false {
        didSet {
            if internetConnectionAvailable && oldValue == false {
                
                print("Internet Connection status changed to true!")
                
                if saved && !savedInCloud {
                    saveDataInCloud(UIApplication.sharedApplication()) ///////// Test this
                }
                
                if shouldLoad && !notificationsEnabled {
                    CloudKitHelper().loadAll()
                    shouldLoad = false
                }
                
                let userDefaults = NSUserDefaults.standardUserDefaults()
                if !userDefaults.boolForKey("Launched Before") {
                    CloudKitHelper().handleFirstTime()
                }
            }
        }
    }
    
    
//# MARK: - Prebuild methods
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.None, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        DataModel().loadUserDefaults()
        Reachability().trackConnectionStatus()

        return true
    }
    
    
    func applicationDidBecomeActive(application: UIApplication) {
        
        print("") ///////////////////////////////////////////////////////////////
        
        resetWastedTimeStopWatch()
        startStopWatches()
        CoreDataHelper().loadCoreDataValues()
        
        saved = false
        savedInCloud = false
        appIsActive = true
        
        if internetConnectionAvailable && !AppData.userID.isEmpty {
            CloudKitHelper().loadAll()
            shouldLoad = false
        } else if !AppData.userID.isEmpty {
            shouldLoad = true
        }
        
    }
    
    
    func applicationWillEnterForeground(application: UIApplication) {
        var i = 0
        while cloudUpdatesInProgress {
            i += 1
            if i > 1000000 { break } // a way to invalidate pending updates? However that shouldn't be a problem considering saving 
        }
    }
    

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("Application received remote notification!")
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        if cloudKitNotification.notificationType == .Query {
            let queryNotification = cloudKitNotification as! CKQueryNotification
            
            if queryNotification.recordID?.recordName == "masterGlobal" {
                let database = CKContainer.defaultContainer().publicCloudDatabase
                database.fetchRecordWithID(queryNotification.recordID!)
                { record, error in
                    if error != nil {
                        print ("ERROR fetching Master Global record update, error \(error?.localizedDescription)")
                    } else {
                        AppData.lastMasterGlobalDataUpdateTime = NSDate()
                        for (key, _) in AppData.masterGlobalData {
                            AppData.masterGlobalData[key] = record![key] as? Double
                        }
                    }
                    
                }
                
            } else {
                
                let database = CKContainer.defaultContainer().privateCloudDatabase
                database.fetchRecordWithID(queryNotification.recordID!)
                { record, error in
                    if error != nil {
                        print ("ERROR fetching User Private record update, error \(error?.localizedDescription)")
                    } else {
                        AppData.lastUserPrivateDataUpdateTime = NSDate()
                        if AppData.userPrivateData["updateID"] == record!["updateID"] as? Double {
                            for (key, _) in AppData.userPrivateData {
                                AppData.userPrivateData[key] = record![key] as? Double
                            }
                        } else {
                            AppData.tmpData = AppData.userPrivateData
                            for (key, _) in AppData.userPrivateData {
                                AppData.userPrivateData[key] = record![key] as? Double
                            }
                            DataModel().resolveUserPrivateDataConflict()
                        }
                    }
                }
            }
        }
    }
    
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("Registered for notifications successfully!")
        notificationsEnabled = true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        
        print("") ///////////////////////////////////////////////////////////////
        
        stopStopWatches()
        saveData(application)
        appIsActive = false
    }

    func applicationDidEnterBackground(application: UIApplication) {
        stopStopWatches()
        saveData(application)
        appIsActive = false
    }
    
    func applicationWillTerminate(application: UIApplication) {
        saveData(application)
    }
    
    
    
    
//# MARK: - Helper methods
    
    func startStopWatches() {
        GlobalStopWatches.currentWastedTimeStopWatch.start()
        GlobalStopWatches.idleStopWatch.start()
    }
    
    func stopStopWatches() {
        GlobalStopWatches.currentWastedTimeStopWatch.stop()
        GlobalStopWatches.idleStopWatch.reset()
    }
    
    func resetWastedTimeStopWatch() {
        GlobalStopWatches.currentWastedTimeStopWatch.reset()
    }
    
    func saveData(application: UIApplication) {
        if !saved {
            DataModel().updateUserPrivateDataValues()
            DataModel().updateMasterGlobalDataValues()
            CoreDataHelper().updateCoreDataValues("UserPrivateData")
            CoreDataHelper().updateCoreDataValues("MasterGlobalData")
            if internetConnectionAvailable && !AppData.userID.isEmpty {
                saveDataInCloud(application)
                savedInCloud = true
            }
            saved = true
        }
    }
    
    func saveDataInCloud(application: UIApplication) {
        CloudKitHelper().UpdateAll(application)
    }
    
    
}