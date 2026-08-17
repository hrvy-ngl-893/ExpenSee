//
//  SpendingActivityAttributes.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//


import ActivityKit
import Foundation
#if os(iOS)
public struct SpendingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state updated during the Live Activity lifecycle
        var remainingBudget: Decimal
        var spentToday: Decimal
        var baseDailyLimit: Decimal
        var lastExpenseAmount: Decimal?
        var lastExpenseCategory: String?
        
        var progressValue: Double {
            guard baseDailyLimit > 0 else { return 0 }
            return NSDecimalNumber(decimal: (baseDailyLimit - spentToday) / baseDailyLimit).doubleValue
        }
    }

    // Fixed non-changing properties
    var budgetCycleName: String
}
#endif
