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
    @IBOutlet weak var loadingLabel: UILabel!
    
    var productsArray: [SKProduct] = []
    var productIDs: [String] = []
    var productsLoaded = false
    var selectedProductIndex: Int!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var internetConnection = false
    
//    var userName = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(internetUp), name: "internet up", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(internetDown), name: "internet down", object: nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        resetIdleTime()
        GlobalStopWatches.currentWastedTimeStopWatch.callback = self.tick
        
        if !productsLoaded {
            self.loadingLabel.hidden = false
            self.productsTableView.hidden = true
            self.productIDs = AppData.inAppPurchaseIDs.keys.sort()
            self.setTableViewPreferences()
            self.requestProductInfo()
            SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        } else {
            self.loadingLabel.hidden = true
            self.productsTableView.hidden = false
        }
        
        self.internetConnection = appDelegate.internetConnectionAvailable
        if self.internetConnection {
            self.internetUp()
        } else {
            self.internetDown()
        }
        
    }
    
    
    func internetUp() {
        self.internetConnection = true
        if productsLoaded {
            self.productsTableView.hidden = false
            self.loadingLabel.hidden = true
            self.loadingLabel.text = "Loading products"
        } else {
            self.loadingLabel.text = "Loading products"
        }
    }
    
    
    func internetDown() {
        self.internetConnection = false
        self.productsTableView.hidden = true
        self.loadingLabel.hidden = false
        self.loadingLabel.text = "Wasting money is only possible with internet connection"
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
            self.loadingLabel.text = "Cannot perform In App Purchases"
            print("Cannot perform In App Purchases")
        }
    }
    
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        if response.products.count != 0 {
            for product in response.products {
                productsArray.append(product)
            }
            self.productsLoaded = true
            self.loadingLabel.hidden = true
            self.productsTableView.hidden = false
            self.productsTableView.reloadData()
        } else {
            self.loadingLabel.text = "No products found"
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
                dispatch_async(dispatch_get_main_queue()) {
                   SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                }
                
                let purchasedItem = self.productIDs[self.selectedProductIndex]
                let purchaseAmount = AppData.inAppPurchaseIDs[purchasedItem]
                if AppData.userPrivateData["moneyWasted"] == 0 {
                    AppData.masterGlobalData["numberOfPaidUsers"]! += 1
                }
                AppData.userPrivateData["moneyWasted"]! += purchaseAmount!
                AppData.thisSessionMoneyWaste += purchaseAmount!
                CloudKitHelper().updateUserWastedMoney()
                CoreDataHelper().updateCoreDataValues("UserPrivateData")
                DataModel().updateMasterWastedMoney()
                CloudKitHelper().updateMasterGlobalData()
                print("Payment transaction completed successfully!")
                
//                self.nameAlert()
                
            case SKPaymentTransactionState.Failed:
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                AppData.purchaseInProgress = false
                print("Payment transaction failed!")
                
            default:
                print("Payment transaction default case: \(transaction.transactionState.rawValue)")
                
            }
        }
    }
    
    
    func showActions() {
        if AppData.purchaseInProgress {
            return
        }
        
        let actionSheetController = UIAlertController(title: productsArray[selectedProductIndex].localizedTitle, message: "Proceed with purchase?", preferredStyle: UIAlertControllerStyle.Alert)
        let buyAction = UIAlertAction(title: "Buy", style: UIAlertActionStyle.Default)
        { (action) -> Void in
            let payment = SKPayment(product: self.productsArray[self.selectedProductIndex])
            SKPaymentQueue.defaultQueue().addPayment(payment)
            AppData.purchaseInProgress = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) {(action) -> Void in}
        
        actionSheetController.addAction(cancelAction)
        actionSheetController.addAction(buyAction)
        presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    
//    func nameAlert() {
//        let alert = UIAlertController(title: "Thank you", message: "Please enter your name", preferredStyle: .Alert)
//        alert.addTextFieldWithConfigurationHandler { (textField) in
//            textField.placeholder = "Your name"
//        }
//        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(action) -> Void in
//            let textField = alert.textFields![0] as UITextField
//            self.userName = textField.text!
//            print(self.userName)
//            AppData.purchaseInProgress = false
//        }))
//        self.presentViewController(alert, animated: true, completion: nil)
//    }
    
    
// MARK: TableView method implementation
    
    func setTableViewPreferences() {
        productsTableView.delegate = self
        productsTableView.dataSource = self
        productsTableView.tableFooterView = UIView.init(frame: CGRectMake(0, 0, productsTableView.contentSize.width, 1))
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