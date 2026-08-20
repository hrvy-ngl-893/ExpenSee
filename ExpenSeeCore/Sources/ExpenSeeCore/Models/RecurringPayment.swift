//
//  RecurringPayment.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/15/26.
//
//  Absorbs the old Deduction model — government deductions, subscriptions,
//  and utilities are all recurring payments that differ only in `kind`.
//
//  CHANGE: added `currencyCode`, following the same pattern as
//  SpendingLimit — derived live from `account.currencyCode` when this
//  payment is scoped to an account, falling back to an explicit value
//  otherwise, so it can't go stale the way SpendingLimit's did before that
//  fix. BudgetEngine.calculateRemainingToday already reads
//  `recurringPayment.currencyCode` to convert each deduction into the
//  daily budget's currency — this was the missing piece that made that
//  code not compile.
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

    /// Backing storage for `currencyCode` — ONLY meaningful when `account`
    /// is nil. When `account` is set, `currencyCode` reads
    /// `account.currencyCode` live instead. Don't read this directly; use
    /// `currencyCode`.
    public var explicitCurrencyCode: String?

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

    /// The currency `amount` is denominated in. Derived live from
    /// `account.currencyCode` whenever this payment is scoped to an
    /// account, so it can't drift if the account's currency changes later.
    /// Falls back to the explicit currency supplied at creation for
    /// account-less (e.g. "general subscriptions") payments.
    public var currencyCode: String {
        get { account?.currencyCode ?? explicitCurrencyCode ?? "USD" }
        set {
            if account != nil {
                #if DEBUG
                assertionFailure("RecurringPayment '\(name)' is account-scoped — its currency always follows \(account!.name)'s currency and can't be set directly. Change the account's currency instead, or clear `account` first.")
                #endif
                return
            }
            explicitCurrencyCode = newValue
        }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        currencyCode: String? = nil,
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

        if let account {
            #if DEBUG
            if let currencyCode, currencyCode != account.currencyCode {
                assertionFailure("RecurringPayment '\(name)' was given currencyCode \(currencyCode) but its account \(account.name) is in \(account.currencyCode) — account-scoped payments always use the account's currency, so the explicit value is ignored.")
            }
            #endif
            self.explicitCurrencyCode = nil
        } else {
            #if DEBUG
            if currencyCode == nil {
                assertionFailure("RecurringPayment '\(name)' created with no account and no explicit currencyCode — defaulting to USD. Pass one explicitly for account-less payments.")
            }
            #endif
            self.explicitCurrencyCode = currencyCode ?? "USD"
        }
    }
}

// MARK: - Migration note
//
// If you already have RecurringPayment records persisted without this
// property, SwiftData will backfill `explicitCurrencyCode` as nil on
// existing rows (it's Optional, so no migration plan is required) — the
// computed `currencyCode` getter then falls back to "USD" for any
// account-less existing record. Double-check that's the right assumption
// for your existing data; if not, run a one-time pass setting
// `explicitCurrencyCode` on the affected rows after upgrade.
