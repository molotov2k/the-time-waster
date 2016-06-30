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
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
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
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
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
        print("CoreData - Load successfull!")
    }
    
    
    func updateCoreDataValues(type: String) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
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
    
    
}