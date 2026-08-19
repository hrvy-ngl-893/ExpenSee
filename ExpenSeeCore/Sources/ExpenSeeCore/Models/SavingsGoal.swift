//
//  SavingsGoal.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/19/26.
//
//  New model for "savings targets". Progress is derived from the income
//  transactions contributed to it, rather than a separately stored running
//  total that could drift out of sync.
//

import Foundation
import SwiftData

@Model
public final class SavingsGoal: Identifiable {
    public var id: UUID
    public var name: String = ""
    public var targetAmount: Decimal = 0
    public var targetDate: Date?
    public var isActive: Bool = true

    /// The account this goal's contributions are drawn from, if tracked
    /// against a specific account rather than income in general.
    @Relationship public var account: Account?

    @Relationship(deleteRule: .nullify, inverse: \Transaction.savingsGoal)
    public var contributions: [Transaction] = []

    /// Sum of all income transactions linked to this goal. Computed, not
    /// stored, so it can never drift out of sync with the underlying
    /// transactions.
    public var currentAmount: Decimal {
        contributions.reduce(0) { $0 + $1.amount }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Decimal,
        targetDate: Date? = nil,
        isActive: Bool = true,
        account: Account? = nil
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.targetDate = targetDate
        self.isActive = isActive
        self.account = account
    }
}
