//
//  SpendingLimit.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/15/26.
//
//  Renamed from Budget, to leave the name "Budget" free for a future
//  broader budgeting/envelope concept if you build one later. This model is
//  specifically a ceiling amount over a period.
//

import Foundation
import SwiftData

@Model
public final class SpendingLimit: Identifiable {
    public var id: UUID
    public var name: String = ""
    public var limitAmount: Decimal = 0
    public var periodRawValue: String = RecurrenceFrequency.daily.rawValue

    // Only used when period == .custom.
    public var startDate: Date = Date.now
    public var endDate: Date?
    /// Only meaningful when period == .custom — how often this custom-range
    /// limit renews. Leave nil for a one-off limit.
    public var repeatFrequencyRawValue: String?
    public var isActive: Bool = true

    @Relationship public var category: SpendingCategory?
    @Relationship(deleteRule: .nullify, inverse: \Transaction.spendingLimit)
    public var transactions: [Transaction] = []

    public var period: RecurrenceFrequency {
        get { RecurrenceFrequency(rawValue: periodRawValue) ?? .daily }
        set { periodRawValue = newValue.rawValue }
    }

    public var repeatFrequency: RecurrenceFrequency? {
        get {
            guard let raw = repeatFrequencyRawValue else { return nil }
            return RecurrenceFrequency(rawValue: raw)
        }
        set { repeatFrequencyRawValue = newValue?.rawValue }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        limitAmount: Decimal,
        period: RecurrenceFrequency = .daily,
        startDate: Date = .now,
        endDate: Date? = nil,
        repeatFrequency: RecurrenceFrequency? = nil,
        isActive: Bool = true,
        category: SpendingCategory? = nil
    ) {
        self.id = id
        self.name = name
        self.limitAmount = limitAmount
        self.periodRawValue = period.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.repeatFrequencyRawValue = repeatFrequency?.rawValue
        self.isActive = isActive
        self.category = category
    }
}
