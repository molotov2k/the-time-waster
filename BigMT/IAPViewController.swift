//
//  IAPViewController.swift
//  BigMT
//
//  Created by Max Tkach on 7/5/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import UIKit
import StoreKit

class IAPViewController: UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @IBOutlet weak var currentlyWastedTimeLabel: UILabel!
    @IBOutlet weak var productsTableView: UITableView!
    
    var productsArray: [SKProduct] = []
    var productIDs: [String] = []
    var productsLoaded = false
    var selectedProductIndex: Int!
    var transactionInProgress = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        resetIdleTime()
        GlobalStopWatches.currentWastedTimeStopWatch.callback = self.tick
        
        if !productsLoaded {
            productIDs = AppData.inAppPurchaseIDs.keys.sort()
            setTableViewPreferences()
            requestProductInfo()
            SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        }
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
    
    
// MARK: IAP method implementation
    
    func requestProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            let productIdentifiers = Set(productIDs)
            let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            productRequest.delegate = self
            productRequest.start()
        } else {
            print("Cannot perform In App Purchases.")
        }
    }
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        if response.products.count != 0 {
            for product in response.products {
                productsArray.append(product)
            }
            productsLoaded = true
            productsTableView.reloadData()
        } else {
            print("No products found")
        }
        
        if response.invalidProductIdentifiers.count != 0 {
            print(response.invalidProductIdentifiers.description)
        }
    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
                
            case SKPaymentTransactionState.Purchased:
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                transactionInProgress = false
                let purchasedItem = productIDs[selectedProductIndex]
                let purchaseAmount = AppData.inAppPurchaseIDs[purchasedItem]
                if AppData.userPrivateData["moneyWasted"] == 0 {
                    AppData.masterGlobalData["numberOfPaidUsers"]! += 1
                }
                AppData.userPrivateData["moneyWasted"]! += purchaseAmount!
                AppData.thisSessionMoneyWaste += purchaseAmount!
                CloudKitHelper().updateUserWastedMoney()
                CoreDataHelper().updateCoreDataValues("UserPrivateData")
                print("Payment transaction completed successfully!")
                
            case SKPaymentTransactionState.Failed:
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                transactionInProgress = false
                print("Payment transaction failed!")
                
            default:
                print(transaction.transactionState.rawValue) // remove
                
            }
        }
    }
    
    func showActions() {
        if transactionInProgress {
            return
        }
        
        let actionSheetController = UIAlertController(title: productsArray[selectedProductIndex].localizedTitle, message: "Proceed with purchase?", preferredStyle: UIAlertControllerStyle.Alert)
        let buyAction = UIAlertAction(title: "Buy", style: UIAlertActionStyle.Default)
        { (action) -> Void in
            let payment = SKPayment(product: self.productsArray[self.selectedProductIndex])
            SKPaymentQueue.defaultQueue().addPayment(payment)
            self.transactionInProgress = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) {(action) -> Void in}
        
        actionSheetController.addAction(cancelAction)
        actionSheetController.addAction(buyAction)
        presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    
// MARK: TableView method implementation
    
    func setTableViewPreferences() {
        productsTableView.delegate = self
        productsTableView.dataSource = self
        productsTableView.tableFooterView = UIView.init(frame: CGRectMake(0, 0, productsTableView.contentSize.width, 1))
        //productsTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        if productsTableView.contentSize.height < productsTableView.frame.size.height {
            productsTableView.scrollEnabled = false
        } else {
            productsTableView.scrollEnabled = true
        }
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productsArray.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("IAPCell", forIndexPath: indexPath)
        let product = productsArray[indexPath.row]
        cell.textLabel!.text = product.localizedTitle
        cell.detailTextLabel!.text = product.localizedDescription
        cell.detailTextLabel!.textColor = UIColor.grayColor()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedProductIndex = indexPath.row
        showActions()
        tableView.cellForRowAtIndexPath(indexPath)?.selected = false
    }
    
}