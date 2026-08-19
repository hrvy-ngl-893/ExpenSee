//
//  SpendingActivityAttributes.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import Foundation
#if canImport(ActivityKit)
#if os(iOS)
import ActivityKit

public struct SpendingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Using Double because ActivityKit's Codable conformance handles
        // Double more predictably than Decimal across the Live Activity
        // widget extension boundary.
        public var remainingBudget: Double
        public var spentToday: Double

        public init(remainingBudget: Double, spentToday: Double) {
            self.remainingBudget = remainingBudget
            self.spentToday = spentToday
        }
    }

    public var dailyLimit: Double

    public init(dailyLimit: Double) {
        self.dailyLimit = dailyLimit
    }
}
#endif // os(iOS)
#endif // canImport(ActivityKit)
