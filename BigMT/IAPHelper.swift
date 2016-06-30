//
//  IAPHelper.swift
//  BigMT
//
//  Created by Max Tkach on 6/28/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (success: Bool, products: [SKProduct]?) -> ()

public class IAPHelper : NSObject  {
    
    static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    
    public init(productIds: Set<ProductIdentifier>) {
        super.init()
    }
}

// MARK: - StoreKit API

extension IAPHelper {
    
    public func requestProducts(completionHandler: ProductsRequestCompletionHandler) {
        completionHandler(success: false, products: [])
    }
    
    public func buyProduct(product: SKProduct) {
    }
    
    public func isProductPurchased(productIdentifier: ProductIdentifier) -> Bool {
        return false
    }
    
    public class func canMakePayments() -> Bool {
        return true
    }
    
    public func restorePurchases() {
    }
}
