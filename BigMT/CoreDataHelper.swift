//
//  CoreDataHelper.swift
//  BigMT
//
//  Created by Max Tkach on 6/24/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataHelper {
    
    var data = [NSManagedObject]()
    
    
    func createInitialCoreDataRecord() {
        
        let managedContext = self.managedObjectContext
        
        let userPrivateDataEntity = NSEntityDescription.entityForName("UserPrivateData", inManagedObjectContext: managedContext)
        let masterGlobalDataEntity = NSEntityDescription.entityForName("MasterGlobalData", inManagedObjectContext: managedContext)
        let lastSyncedDataEntity = NSEntityDescription.entityForName("LastSyncedData", inManagedObjectContext: managedContext)
        let userPrivateData = NSManagedObject(entity: userPrivateDataEntity!, insertIntoManagedObjectContext: managedContext)
        let masterGlobalData = NSManagedObject(entity: masterGlobalDataEntity!, insertIntoManagedObjectContext: managedContext)
        let lastSyncedData = NSManagedObject(entity: lastSyncedDataEntity!, insertIntoManagedObjectContext: managedContext)
        
        for (key, _ ) in AppData.userPrivateData {
            userPrivateData.setValue(AppData.userPrivateData[key], forKey: key)
            lastSyncedData.setValue(AppData.userPrivateData[key], forKey: key)
        }
        for (key, _ ) in AppData.masterGlobalData {
            masterGlobalData.setValue(AppData.masterGlobalData[key], forKey: key)
        }
        
        do {
            try managedContext.save()
            data.append(userPrivateData)
            data.append(masterGlobalData)
            data.append(lastSyncedData)

            print("CoreData record created successfully")
            
        } catch let error as NSError {
            print("CoreData initial saving error: \(error.localizedDescription)")
        }
    }
    
    
    func loadCoreDataValues() {
        
        let managedContext = self.managedObjectContext
        
        let userPrivateDataFetchRequest = NSFetchRequest(entityName: "UserPrivateData")
        let masterGlobalDataFetchRequest = NSFetchRequest(entityName: "MasterGlobalData")
        let lastSyncedDataFetchRequest = NSFetchRequest(entityName: "LastSyncedData")
        
        do {
            let userPrivateResults = try managedContext.executeFetchRequest(userPrivateDataFetchRequest)
            let masterGlobalResults = try managedContext.executeFetchRequest(masterGlobalDataFetchRequest)
            let lastSyncedResults = try managedContext.executeFetchRequest(lastSyncedDataFetchRequest)
            
            let loadedUserPrivateData = userPrivateResults[0] as! NSManagedObject
            let loadedMasterGlobalData = masterGlobalResults[0] as! NSManagedObject
            let loadedLastSyncedData = lastSyncedResults[0] as! NSManagedObject
            
            for (key, _ ) in AppData.userPrivateData {
                AppData.userPrivateData[key] = loadedUserPrivateData.valueForKey(key) as? Double
                AppData.lastSyncedData[key] = loadedLastSyncedData.valueForKey(key) as? Double
            }
            for (key, _ ) in AppData.masterGlobalData {
                AppData.masterGlobalData[key] = loadedMasterGlobalData.valueForKey(key) as? Double
            }
            
        } catch let error as NSError {
            print("CoreData loading error: \(error.localizedDescription)")
        }
        print("CoreData - Loaded successfully!")
    }
    
    
    func updateCoreDataValues(type: String) {
        
        let managedContext = self.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: type)
        
        do {
            
            let results = try managedContext.executeFetchRequest(fetchRequest)
            let loadedData = results[0] as! NSManagedObject
            
            if type == "UserPrivateData" {
                for (key, _) in AppData.userPrivateData {
                    loadedData.setValue(AppData.userPrivateData[key], forKey: key)
                }
            } else if type == "MasterGlobalData" {
                for (key, _) in AppData.masterGlobalData {
                    loadedData.setValue(AppData.masterGlobalData[key], forKey: key)
                }
            } else if type == "LastSyncedData" {
                for (key, _) in AppData.lastSyncedData {
                    loadedData.setValue(AppData.lastSyncedData[key], forKey: key)
                }
            }
            
            do {
                try loadedData.managedObjectContext?.save()
            } catch let error as NSError {
                print("CoreData updating error while writing new values, error: \(error.localizedDescription)")
            }
            
        } catch let error as NSError {
            print("CoreData updating error while fetching, error: \(error.localizedDescription)")
        }
        print("CoreData - \(type) updated successfully!")
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