//
//  CloudKitHelper.swift
//  BigMT
//
//  Created by Max Tkach on 6/19/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitHelper {
    var container: CKContainer
    var userPrivateData: CKDatabase
    var masterGlobalData: CKDatabase
    var inAppPurchasesData: CKDatabase
    
    init() {
        container = CKContainer.defaultContainer()
        userPrivateData = container.privateCloudDatabase
        masterGlobalData = container.publicCloudDatabase
        inAppPurchasesData = container.publicCloudDatabase
    }
    
    func loadAll() {
        self.loadPrivateData()
        self.loadMasterData()
    }
    
    func UpdateAll() {
        self.updateUserPrivateData()
        self.updateMasterGlobalData()
    }
    
    
    func handleFirstTime() {
        container.fetchUserRecordIDWithCompletionHandler({
            id, error in
            if error == nil {
                AppData.userID = String(id!.recordName.characters.dropFirst())
                self.saveUserPrivateData()
                let userDefaults = NSUserDefaults.standardUserDefaults()
                userDefaults.setBool(true, forKey: "Launched Before")
                userDefaults.setValue(AppData.userID, forKey: "UserID")
            } else {
                print("ERROR in Get UserID, error \(error?.localizedDescription)")
            }
        })
    }
    
    
    func loadPrivateData() {
        let recordID = CKRecordID.init(recordName: AppData.userID)
        userPrivateData.fetchRecordWithID(recordID)
        { result, error in
            if error != nil {
                print("ERROR in Load Private Data, error \(error?.localizedDescription)")
            } else {
                AppData.lastUserPrivateDataUpdateTime = NSDate()
                if let result = result {
                    if AppData.userPrivateData["updateID"] == result["updateID"] as? Double {
                        for (key, _) in AppData.userPrivateData {
                            AppData.userPrivateData[key] = result[key] as? Double
                        }
                    } else {
                        AppData.tmpData = AppData.userPrivateData
                        for (key, _) in AppData.userPrivateData {
                            AppData.userPrivateData[key] = result[key] as? Double
                        }
                        DataModel().resolveUserPrivateDataConflict()
                    }
                    print("CloudKit - UserPrivateData loaded successfully!")
                }
            }
        }
    }
    
    
    func loadMasterData() {
        let recordID = CKRecordID.init(recordName: "masterGlobal")
        masterGlobalData.fetchRecordWithID(recordID)
        { result, error in
            if error != nil {
                print("ERROR in Load Master Data, error \(error?.localizedDescription)")
            } else {
                AppData.lastMasterGlobalDataUpdateTime = NSDate()
                if let result = result {
                    for (key, _) in AppData.masterGlobalData {
                        AppData.masterGlobalData[key] = result[key] as? Double
                    }
                    print("CloudKit - MastedGlobalData loaded successfully!")
                }
            }
        }
    }
    
    
    func loadInAppPurchasesData() {
        let predicate = NSPredicate.init(value: true)
        let query = CKQuery.init(recordType: "inAppPurchases", predicate: predicate)
        
        inAppPurchasesData.performQuery(query, inZoneWithID: nil)
        { records, error in
            if error != nil {
                print("ERROR in Load InAppPurchases Data, error \(error?.localizedDescription)")
            } else {
                if let records = records {
                    for record in records {
                        AppData.inAppPurchaseIDs.append(record["name"] as! String)
                    }
                    AppData.inAppPurchaseIDs.sortInPlace()
                    print("CloudKit - InAppPurchases loaded successfully!")
                }
            }
            
        }
    }
    

    func saveUserPrivateData() {
        let recordID = CKRecordID.init(recordName: AppData.userID)
        let record = CKRecord(recordType: "userPrivateData", recordID: recordID)
        for (key, value) in AppData.userPrivateData {
            record.setValue(value, forKey: key)
        }
        userPrivateData.saveRecord(record, completionHandler:
            { record, error in
                if let fetchError = error {
                    print("*** Saving error occurred in \(fetchError.localizedDescription) ***")
                } else {
                    AppData.newUser = true
                    self.subscribeToUserPrivateDataUpdates() // part of handling the first time
                    self.subscribeToMasterGlobalDataUpdates()
                    // do I need both subscriptions for every user?
                    print("User Private Data saved successfully!")
                }
        })
    }
    
    
    func updateUserPrivateData() {
        let recordID = CKRecordID.init(recordName: AppData.userID)
        userPrivateData.fetchRecordWithID(recordID)
        { fetchedData, error in
            guard let fetchedData = fetchedData else {
                print("ERROR during loading in Update User Private Data, error \(error?.localizedDescription)")
                return
            }
            if AppData.userPrivateData["updateID"] == fetchedData["updateID"] as? Double {
                for (key, value) in AppData.userPrivateData {
                    fetchedData[key] = value
                }
                AppData.userPrivateData["updateID"] = Double(arc4random())
            } else {
                AppData.tmpData = AppData.userPrivateData
                for (key, _) in AppData.userPrivateData {
                    AppData.userPrivateData[key] = fetchedData[key] as? Double
                }
                DataModel().resolveUserPrivateDataConflict()
                self.updateUserPrivateData()
            }
            self.userPrivateData.saveRecord(fetchedData)
            { savedData, error in
                if (error != nil) {
                    print("ERROR during saving in Update User Private Data, error \(error?.localizedDescription)")
                } else {
                    print("CloudKit - UserPrivateData updated successfully!")
                }
            }
        }
    }
    
    
    func updateMasterGlobalData() {
        let recordID = CKRecordID.init(recordName: "masterGlobal")
        masterGlobalData.fetchRecordWithID(recordID)
        { fetchedData, error in
            guard let fetchedData = fetchedData else {
                print("ERROR during loading in Update Master Global Data, error \(error?.localizedDescription)")
                return
            }
            if AppData.masterGlobalData["updateID"] == fetchedData["updateID"] as? Double {
                for (key, value) in AppData.masterGlobalData {
                    fetchedData[key] = value
                }
                AppData.masterGlobalData["updateID"] = Double(arc4random())
            } else {
                self.loadMasterData()
                self.updateMasterGlobalData()
                return
            }
            self.masterGlobalData.saveRecord(fetchedData)
            { savedData, error in
                if (error != nil) {
                    print("ERROR during saving in Update Master Global Data, error \(error?.localizedDescription)")
                } else {
                    print("CloudKit - MasterGlobalData updated successfully!")
                }
            }
        }
    }
    
    
    func subscribeToMasterGlobalDataUpdates() {
        let recordID = CKRecordID.init(recordName: "masterGlobal")
        let predicate = NSPredicate(value: recordID.recordName == "masterGlobal")
        let subscription = CKSubscription.init(recordType: "masterGlobalData", predicate: predicate, options: CKSubscriptionOptions.FiresOnRecordUpdate)
        subscription.notificationInfo = CKNotificationInfo.init()
        masterGlobalData.saveSubscription(subscription)
        { subscription, error in
            if error != nil {
                print("ERROR in Master Global Data subscription, error \(error?.localizedDescription)")
            } else {
                print("Master Global Data - Subscription added!")
            }
        }
    }
    
    
    func subscribeToUserPrivateDataUpdates() {
        let recordID = CKRecordID.init(recordName: AppData.userID)
        let predicate = NSPredicate(value: recordID.recordName == AppData.userID)
        let subscription = CKSubscription.init(recordType: "userPrivateData", predicate: predicate, options: CKSubscriptionOptions.FiresOnRecordUpdate)
        subscription.notificationInfo = CKNotificationInfo.init()
        userPrivateData.saveSubscription(subscription)
        { subscription, error in
            if error != nil {
                print("ERROR in User Private Data subscription, error \(error?.localizedDescription)")
            } else {
                print("User Private Data - Subscription added!")
            }
        }
    }
    
    
//    func errorUpdating(error: NSError) {
//        let message = error.localizedDescription
//        let alert = UIAlertController(title: "Error loading data", message: message, preferredStyle: UIAlertControllerStyle.Alert)
//        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
//        self.presentViewController(alert, animated: true, completion: nil)
//    }
    
    
    
    
    
}