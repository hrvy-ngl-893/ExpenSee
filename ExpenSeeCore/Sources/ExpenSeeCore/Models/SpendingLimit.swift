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
//  CHANGES FROM ORIGINAL:
//  - `currencyCode` is now a *computed* property instead of a stored one.
//    Previously it was captured once at init time from `account.currencyCode`
//    and then never touched again — if you later edited the account's
//    currency (or reassigned the limit to a different account), the limit's
//    currencyCode went stale and silently stopped matching any transactions
//    in BudgetEngine.calculateSpent. Now it's always read live from the
//    account when one is set, so it can never drift.
//  - `category: SpendingCategory?` -> `categories: [SpendingCategory]` so a
//    limit can watch more than one category (multi-select).
//

import Foundation
import SwiftData

@Model
public final class SpendingLimit: Identifiable {
    public var id: UUID
    public var name: String = ""
    public var limitAmount: Decimal = 0

    /// Backing storage for `currencyCode` — ONLY meaningful when `account`
    /// is nil (a category-wide or fully global limit). When `account` is
    /// set, `currencyCode` ignores this and reads `account.currencyCode`
    /// live instead, so it can't go stale. Don't read this directly; use
    /// `currencyCode`.
    public var explicitCurrencyCode: String?

    public var periodRawValue: String = RecurrenceFrequency.daily.rawValue

    // Only used when period == .custom.
    public var startDate: Date = Date.now
    public var endDate: Date?
    /// Only meaningful when period == .custom — how often this custom-range
    /// limit renews. Leave nil for a one-off limit.
    public var repeatFrequencyRawValue: String?
    public var isActive: Bool = true

    /// Optional: scopes this limit to a single account. When set, only that
    /// account's transactions count toward the limit (still filtered by
    /// category too, if any are also set), and this is the live source of
    /// truth for `currencyCode`. Leave nil for a limit meant to track spend
    /// across all accounts in a given currency (e.g. category-wide budgets).
    @Relationship public var account: Account?

    /// Categories this limit watches. Empty means "any category" (an
    /// account-wide or fully global limit). Non-empty means a transaction
    /// must match ONE of these categories to count — this is the multi-select
    /// you asked about; there's no need for a separate "custom" case, any
    /// limit can watch zero, one, or several categories.
    @Relationship public var categories: [SpendingCategory] = []

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

    /// The currency `limitAmount` is denominated in. Derived live from
    /// `account.currencyCode` whenever this limit is account-scoped, so it
    /// can never go stale relative to the account. Falls back to the
    /// explicit currency you supplied at creation for account-less
    /// (category-wide / global) limits.
    public var currencyCode: String {
        get { account?.currencyCode ?? explicitCurrencyCode ?? "USD" }
        set {
            if account != nil {
                #if DEBUG
                assertionFailure("SpendingLimit '\(name)' is account-scoped — its currency always follows \(account!.name)'s currency and can't be set directly. Change the account's currency instead, or clear `account` first.")
                #endif
                return
            }
            explicitCurrencyCode = newValue
        }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        limitAmount: Decimal,
        currencyCode: String? = nil,
        period: RecurrenceFrequency = .daily,
        startDate: Date = .now,
        endDate: Date? = nil,
        repeatFrequency: RecurrenceFrequency? = nil,
        isActive: Bool = true,
        account: Account? = nil,
        categories: [SpendingCategory] = []
    ) {
        self.id = id
        self.name = name
        self.limitAmount = limitAmount
        self.account = account

        if let account {
            #if DEBUG
            if let currencyCode, currencyCode != account.currencyCode {
                assertionFailure("SpendingLimit '\(name)' was given currencyCode \(currencyCode) but its account \(account.name) is in \(account.currencyCode) — account-scoped limits always use the account's currency, so the explicit value is ignored.")
            }
            #endif
            self.explicitCurrencyCode = nil
        } else {
            #if DEBUG
            if currencyCode == nil {
                assertionFailure("SpendingLimit '\(name)' created with no account and no explicit currencyCode — defaulting to USD. Pass one explicitly for category-wide/global limits.")
            }
            #endif
            self.explicitCurrencyCode = currencyCode ?? "USD"
        }

        self.periodRawValue = period.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.repeatFrequencyRawValue = repeatFrequency?.rawValue
        self.isActive = isActive
        self.categories = categories
    }
}

// MARK: - Migration note
//
// Any existing call site using the old single-category initializer param
// (`category: someCategory`) needs to change to `categories: [someCategory]`.
// If you had SwiftData already storing a single `category` relationship,
// write a lightweight migration that wraps the old value into the new
// `categories` array — SwiftData won't do this for you automatically since
// the property name and cardinality both changed.
