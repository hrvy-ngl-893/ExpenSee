//
//  ExpenSeeActivityAttributes.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import ActivityKit
import Foundation

#if os(iOS)
public struct LiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingBudget: Decimal
        var spentToday: Decimal
        var baseDailyLimit: Decimal
        var currencyCode: String
        var lastExpenseAmount: Decimal?
        var lastExpenseCategory: String?
        
        var progressValue: Double {
            guard baseDailyLimit > 0 else { return 0 }
            return NSDecimalNumber(decimal: (baseDailyLimit - spentToday) / baseDailyLimit).doubleValue
        }
    }

    var budgetCycleName: String
}
#endif
