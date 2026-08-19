//
//  Enums.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/19/26.
//

import Foundation

/// How often something recurs, and what period a spending limit represents.
///
/// `.custom` is only meaningful for `SpendingLimit.period` — it signals that
/// the limit uses an explicit `startDate`/`endDate` window rather than a
/// standard calendar period. It has no defined meaning for
/// `RecurringPayment.frequency`.
///
/// `.quincena` represents a semi-monthly pay period (1st–15th, 16th–end of
/// month). The exact day boundaries are computed by the reporting/aggregation
/// layer, not stored here.
public enum RecurrenceFrequency: String, Codable, CaseIterable, Sendable {
    case daily
    case weekly
    case quincena
    case monthly
    case yearly
    case custom
}

public extension RecurrenceFrequency {
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .quincena: return "Quincena"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Custom Range"
        }
    }
}
