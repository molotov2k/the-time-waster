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
    var appIsActive = false
    var notificationsEnabled = false
    var inAppPurchasesLoaded = false
    
    var internetConnectionAvailable = false {
        didSet {
            if internetConnectionAvailable {
                print("Internet Connection status changed to true!")
                
                if !inAppPurchasesLoaded && appIsActive {
                    CloudKitHelper().loadInAppPurchasesData()
                    inAppPurchasesLoaded = true
                }
                
                if saved && !savedInCloud {
                    saveDataInCloud()
                }
                
                let userDefaults = NSUserDefaults.standardUserDefaults()
                if !userDefaults.boolForKey("Launched Before") {
                    CloudKitHelper().handleFirstTime()
                }
                
                if appIsActive && !notificationsEnabled && !AppData.userID.isEmpty {
                    CloudKitHelper().loadAll()
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
        resetWastedTimeStopWatch()
        startStopWatches()
        
        if internetConnectionAvailable {
            CloudKitHelper().loadAll()
            CloudKitHelper().loadInAppPurchasesData()
        } else {
            CoreDataHelper().loadCoreDataValues()
        }
        
        saved = false
        savedInCloud = false
        inAppPurchasesLoaded = false
        appIsActive = true
    }
    

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("RECEIVED NOTIFICATION") ///////////////////////////////////////////////
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
//                database.fetchRecordWithID(queryNotification.recordID!, completionHandler: { (record: CKRecord?, error: NSError?) -> Void in
//                    guard error == nil else {
//                        print ("ERROR fetching Master Global record update, error \(error?.localizedDescription)")
//                        return
//                    }
//                    if queryNotification.queryNotificationReason == .RecordUpdated {
//                        for (key, _) in AppData.masterGlobalData {
//                            AppData.masterGlobalData[key] = record![key] as? Double
//                        }
//                    }
//                })

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
        stopStopWatches()
        appIsActive = false
    }

    func applicationDidEnterBackground(application: UIApplication) {
        stopStopWatches()
        saveData()
        appIsActive = false
    }
    
    func applicationWillTerminate(application: UIApplication) {
        saveData()
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
    
    func saveData() {
        if !saved {
            DataModel().updateUserPrivateDataValues()
            DataModel().updateMasterGlobalDataValues()
            CoreDataHelper().updateCoreDataValues("UserPrivateData")
            CoreDataHelper().updateCoreDataValues("MasterGlobalData")
            saved = true
            
            if internetConnectionAvailable && !AppData.userID.isEmpty {
                saveDataInCloud()
            }
        }
    }
    
    func saveDataInCloud() {
        CloudKitHelper().UpdateAll()
        AppData.lastSyncedData = AppData.userPrivateData
        CoreDataHelper().updateCoreDataValues("LastSyncedData")
        savedInCloud = true
    }
    
    
//# MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("BigMT", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    
}

