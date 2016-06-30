//
//  BigMTProducts.swift
//  BigMT
//
//  Created by Max Tkach on 6/28/16.
//  Copyright © 2016 Anvil. All rights reserved.
//

import Foundation

public struct BigMTProducts {
    
    private static let Prefix = "com.anvil.BigMT."
    
    public static let totalMoneyWasted = Prefix + "TotalMoneyWasted"
    
    private static let productIdentifiers: Set<ProductIdentifier> = [BigMTProducts.totalMoneyWasted]
    
    public static let store = IAPHelper(productIds: BigMTProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(productIdentifier: String) -> String? {
    return productIdentifier.componentsSeparatedByString(".").last
}