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
    let operationQueue = NSOperationQueue()
    
    
//# MARK: - General Stuff
    
    init() {
        container = CKContainer.defaultContainer()
        userPrivateData = container.privateCloudDatabase
        masterGlobalData = container.publicCloudDatabase
        inAppPurchasesData = container.publicCloudDatabase
    }
    
    
    func loadAll() {
        self.loadPrivateData()
        self.loadMasterData()
        self.loadInAppPurchasesData()
    }
    
    
    func UpdateAll() {
        self.updateUserPrivateData()
        self.updateMasterGlobalData()
    }
    
    
    func handleFirstTime() {
        container.fetchUserRecordIDWithCompletionHandler(
            { id, error in
                if error == nil {
                    AppData.userID = String(id!.recordName.characters.dropFirst())
                    self.saveUserPrivateData()
                    let userDefaults = NSUserDefaults.standardUserDefaults()
                    userDefaults.setBool(true, forKey: "Launched Before")
                    userDefaults.setValue(AppData.userID, forKey: "UserID")
                    self.loadAll()
                } else {
                    print("ERROR in Get UserID, error \(error?.localizedDescription)")
                }
        })
    }

    
//# MARK: - Saving Data (part of the handling first time)
    
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
                    self.subscribeToUserPrivateDataUpdates()
                    self.subscribeToMasterGlobalDataUpdates()
                    print("User Private Data saved successfully!")
                }
        })
    }
    

//# MARK: - Loading Data
    
    func loadPrivateData() {
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "userPrivateData", predicate: predicate)
        let loadUserDataOperation = CKQueryOperation(query: query)
        
        loadUserDataOperation.queuePriority = .VeryHigh
        
        loadUserDataOperation.recordFetchedBlock = { result in
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
        }
        
        loadUserDataOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                print("ERROR in Load User Private Data, error: \(error.localizedDescription)")
            } else {
                print("CloudKit - UserPrivateData loaded successfully!")
            }
        }
        
        self.operationQueue.addOperations([loadUserDataOperation], waitUntilFinished: true)
        //self.userPrivateData.addOperation(loadUserDataOperation)
        
    }
    
    
    func loadMasterData() {
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "masterGlobalData", predicate: predicate)
        let loadMasterDataOperation = CKQueryOperation(query: query)

        loadMasterDataOperation.queuePriority = .VeryHigh
        
        loadMasterDataOperation.recordFetchedBlock = { result in
            AppData.lastMasterGlobalDataUpdateTime = NSDate()
            for (key, _) in AppData.masterGlobalData {
                AppData.masterGlobalData[key] = result[key] as? Double
            }
        }
        
        loadMasterDataOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                print("ERROR in Load Master Data, error \(error.localizedDescription)")
            } else {
                print("CloudKit - MastedGlobalData loaded successfully!")
            }
        }
        
        //self.operationQueue.addOperations([loadMasterDataOperation], waitUntilFinished: true)
        self.masterGlobalData.addOperation(loadMasterDataOperation)
        print(self.operationQueue.operationCount)
        
    }
    
    
    func loadInAppPurchasesData() {
        
        let predicate = NSPredicate.init(value: true)
        let query = CKQuery.init(recordType: "inAppPurchases", predicate: predicate)
        let loadPurchasesDataOperation = CKQueryOperation(query: query)
        
        loadPurchasesDataOperation.queuePriority = .VeryHigh
        
        loadPurchasesDataOperation.recordFetchedBlock = { result in
            let recordValue = result["wm_value"] as! Double
            let recordName = result["name"] as! String
            AppData.inAppPurchaseIDs[recordName] = recordValue
        }
        
        loadPurchasesDataOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                print("ERROR in Load InAppPurchases Data, error \(error.localizedDescription)")
            } else {
                print("CloudKit - InAppPurchases loaded successfully!")
            }
            print(AppData.inAppPurchaseIDs)
        }
        
        //self.operationQueue.addOperations([loadPurchasesDataOperation], waitUntilFinished: true)
        self.masterGlobalData.addOperation(loadPurchasesDataOperation)
        
    }
    

//# MARK: - Update Data
    
    func updateUserPrivateData() {
        let recordID = CKRecordID.init(recordName: AppData.userID)
        let record = CKRecord.init(recordType: "userPrivateData", recordID: recordID)
        for (key, value) in AppData.userPrivateData {
            record[key] = value
        }
        
        let updateUserDataOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        updateUserDataOperation.savePolicy = .AllKeys
        updateUserDataOperation.longLived = true
        updateUserDataOperation.queuePriority = .VeryLow
        
        updateUserDataOperation.perRecordCompletionBlock = { records, error in
            if let error = error {
                print("ERROR: \(error.localizedDescription)")
            }
        }

        updateUserDataOperation.modifyRecordsCompletionBlock = { records, IDs, error in
            if let error = error {
                print("ERROR in Update User Private Data, error \(error.localizedDescription)")
            } else {
                print("CloudKit - UserPrivateData updated successfully!")
            }
        }
        
        //self.operationQueue.addOperations([updateUserDataOperation], waitUntilFinished: true)
        self.userPrivateData.addOperation(updateUserDataOperation)
        
    }
    

    func updateMasterGlobalData() {
        let recordID = CKRecordID.init(recordName: "masterGlobal")
        let record = CKRecord.init(recordType: "masterGlobalData", recordID: recordID)
        for (key, value) in AppData.masterGlobalData {
            record[key] = value
        }
        
        let updateMasterDataOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        updateMasterDataOperation.savePolicy = .AllKeys
        updateMasterDataOperation.longLived = true
        updateMasterDataOperation.queuePriority = .VeryLow
        
        updateMasterDataOperation.perRecordCompletionBlock = { records, error in
            if let error = error {
                print("ERROR: \(error.localizedDescription)")
            }
        }
        
        updateMasterDataOperation.modifyRecordsCompletionBlock = { records, IDs, error in
            if let error = error {
                print("ERROR in Update User Private Data, error \(error.localizedDescription)")
            } else {
                print("CloudKit - MasterGlobalData updated successfully!")
            }
        }
        
        self.masterGlobalData.addOperation(updateMasterDataOperation)
        //operationQueue.addOperations([updateMasterDataOperation], waitUntilFinished: true)
        
    }

    
    
    func updateUserWastedMoney() {
        let recordID = CKRecordID.init(recordName: AppData.userID)
        userPrivateData.fetchRecordWithID(recordID)
        { fetchedData, error in
            guard let fetchedData = fetchedData else {
                print("ERROR during Update User Wasted Money, error \(error?.localizedDescription)")
                return
            }
            if AppData.userPrivateData["updateID"] == fetchedData["updateID"] as? Double {
                AppData.userPrivateData["updateID"] = Double(arc4random())
                fetchedData["moneyWasted"] = AppData.userPrivateData["moneyWasted"]
                fetchedData["updateID"] = AppData.userPrivateData["updateID"]
            } else {
                AppData.tmpData = AppData.userPrivateData
                for (key, _) in AppData.userPrivateData {
                    AppData.userPrivateData[key] = fetchedData[key] as? Double
                }
                self.loadPrivateData()
                DataModel().resolveUserPrivateDataConflict()
                self.updateUserWastedMoney()
                return
            }
            self.userPrivateData.saveRecord(fetchedData)
            { savedData, error in
                if (error != nil) {
                    print("ERROR during saving in Update User Wasted Money, error \(error?.localizedDescription)")
                } else {
                    print("CloudKit - User Wasted Money updated successfully")
                }
            }
        }
    }
    
    
//    func updateMasterGlobalData() {
//        appDelegate.updatingCloudMasterData = true
//        let recordID = CKRecordID.init(recordName: "masterGlobal")
//        masterGlobalData.fetchRecordWithID(recordID)
//        { fetchedData, error in
//            guard let fetchedData = fetchedData else {
//                print("ERROR during loading in Update Master Global Data, error \(error?.localizedDescription)")
//                return
//            }
//            if AppData.masterGlobalData["updateID"] == fetchedData["updateID"] as? Double {
//                AppData.masterGlobalData["updateID"] = Double(arc4random())
//                for (key, value) in AppData.masterGlobalData {
//                    fetchedData[key] = value
//                }
//            } else {
//                self.loadMasterData()
//                self.updateMasterGlobalData()
//                return
//            }
//            self.masterGlobalData.saveRecord(fetchedData)
//            { savedData, error in
//                if (error != nil) {
//                    print("ERROR during saving in Update Master Global Data, error \(error?.localizedDescription)")
//                } else {
//                    print("CloudKit - MasterGlobalData updated successfully!")
//                }
//                self.appDelegate.updatingCloudMasterData = false
//            }
//        }
//    }
    
    
    func updateMasterWastedMoney() {
        let recordID = CKRecordID.init(recordName: "masterGlobal")
        masterGlobalData.fetchRecordWithID(recordID)
        { fetchedData, error in
            guard let fetchedData = fetchedData else {
                print("ERROR during loading in Update Master Global Data, error \(error?.localizedDescription)")
                return
            }
            if AppData.masterGlobalData["updateID"] == fetchedData["updateID"] as? Double {
                AppData.masterGlobalData["updateID"] = Double(arc4random())
                DataModel().updateMasterWastedMoney()
                for (key, value) in AppData.masterGlobalData {
                    fetchedData[key] = value
                }
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
    
    
//# MARK: - Subscribe to Notifications
    
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
    
    
}