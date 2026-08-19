//
//  RecurringPayment.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/15/26.

//
//  Absorbs the old Deduction model — government deductions, subscriptions,
//  and utilities are all recurring payments that differ only in `kind`.
//

import Foundation
import SwiftData

public enum RecurringPaymentKind: String, Codable, CaseIterable, Sendable {
    case governmentDeduction
    case subscription
    case utility
    case other
}

@Model
public final class RecurringPayment: Identifiable {
    public var id: UUID
    public var name: String = ""
    public var amount: Decimal = 0
    public var kindRawValue: String = RecurringPaymentKind.other.rawValue
    public var frequencyRawValue: String = RecurrenceFrequency.monthly.rawValue
    public var nextDueDate: Date = Date.now
    public var isActive: Bool = true

    @Relationship public var category: SpendingCategory?
    @Relationship public var account: Account?

    public var kind: RecurringPaymentKind {
        get { RecurringPaymentKind(rawValue: kindRawValue) ?? .other }
        set { kindRawValue = newValue.rawValue }
    }

    public var frequency: RecurrenceFrequency {
        get { RecurrenceFrequency(rawValue: frequencyRawValue) ?? .monthly }
        set { frequencyRawValue = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        kind: RecurringPaymentKind = .other,
        frequency: RecurrenceFrequency = .monthly,
        nextDueDate: Date = .now,
        isActive: Bool = true,
        category: SpendingCategory? = nil,
        account: Account? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.kindRawValue = kind.rawValue
        self.frequencyRawValue = frequency.rawValue
        self.nextDueDate = nextDueDate
        self.isActive = isActive
        self.category = category
        self.account = account
    }
}
