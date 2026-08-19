//
//  Transaction.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

//  Now represents expenses, income, and
//  transfers between accounts via `type`, instead of being implicitly
//  expense-only.
//

import Foundation
import SwiftData

public enum TransactionType: String, Codable, CaseIterable, Sendable {
    case expense
    case income
    case transfer
}

@Model
public final class Transaction: Identifiable {
    public var id: UUID
    public var amount: Decimal = 0
    public var timestamp: Date = Date.now
    public var note: String = ""
    public var typeRawValue: String = TransactionType.expense.rawValue

    /// Snapshot of the account's currency at the time of the transaction, so
    /// historical records stay accurate even if the account's currency is
    /// changed later.
    public var currencyCode: String = "USD"

    @Relationship public var category: SpendingCategory?

    /// The account this transaction affects. For an expense or income, this
    /// is the only account involved. For a transfer, this is the source
    /// (debited) account.
    @Relationship public var account: Account

    /// Only set when `type == .transfer` — the account receiving the funds.
    @Relationship public var destinationAccount: Account?

    /// Only meaningful when `type == .expense` — the spending limit this
    /// transaction counts against, if any.
    @Relationship public var spendingLimit: SpendingLimit?

    /// Only meaningful when `type == .income` — the savings goal this
    /// transaction contributes to, if any.
    @Relationship public var savingsGoal: SavingsGoal?

    public var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        amount: Decimal,
        timestamp: Date = .now,
        note: String = "",
        type: TransactionType = .expense,
        category: SpendingCategory? = nil,
        account: Account,
        destinationAccount: Account? = nil,
        spendingLimit: SpendingLimit? = nil,
        savingsGoal: SavingsGoal? = nil,
        currencyCode: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
        self.note = note
        self.typeRawValue = type.rawValue
        self.category = category
        self.account = account
        self.destinationAccount = destinationAccount
        self.spendingLimit = spendingLimit
        self.savingsGoal = savingsGoal
        self.currencyCode = currencyCode ?? account.currencyCode
    }
}
