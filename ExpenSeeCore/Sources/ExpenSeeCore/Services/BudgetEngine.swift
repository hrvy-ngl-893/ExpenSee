//
//  BudgetEngine.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//
//  CHANGES FROM ORIGINAL:
//  1. FIXED DOUBLE-COUNT BUG: the old matching logic only `return true`'d on
//     an explicit spendingLimit assignment that matched — if it didn't
//     match (i.e. the transaction was explicitly assigned to a DIFFERENT
//     limit), execution fell through into the category/fallback checks for
//     the *current* limit too. That meant a transaction explicitly pinned
//     to Limit A could also get silently swept into Limit B's total if B's
//     category happened to line up — the same expense reducing two limits
//     at once. Fixed: once a transaction has an explicit spendingLimit, it
//     counts ONLY toward that one, full stop.
//  2. Currency mismatches used to be silently EXCLUDED from the total
//     (`guard record.currencyCode == spendingLimit.currencyCode else {
//     return false }`) — a PHP expense on a USD limit just vanished from the
//     total, which reads as "the limit isn't going down." Now, given a
//     `CurrencyConverting`, mismatched-currency transactions are converted
//     into the limit's currency using a cached exchange rate. Foundation
//     has no built-in live FX rates (unlike `Measurement`/`Dimension`,
//     which only handle fixed-ratio units like meters<->feet), so this
//     needs an injected converter backed by a real rate source — see
//     CurrencyConversion.swift. Pass `nil` to keep the old
//     exclude-on-mismatch behavior if you don't want to wire up a
//     converter yet.
//  3. Category matching is now "any of" over `spendingLimit.categories`
//     (multi-select) instead of a single optional category.
//  4. `calculateRemainingToday` now converts recurring-payment and today's
//     expense amounts into the daily limit's currency too, instead of
//     summing raw amounts across currencies as if they were the same unit.
//     NOTE: this assumes `RecurringPayment` has a `currencyCode: String`
//     property (matching the pattern used by Account/Transaction/
//     SpendingLimit) — add one if it doesn't exist yet, or this won't
//     compile.
//

import Foundation
import SwiftData

/// Core domain engine responsible for calculating spending metrics, remaining budget limits,
/// and period status across various budget types and recurring deductions.
public struct BudgetEngine {

    /// Optional currency converter. When nil, cross-currency transactions
    /// are excluded from totals (same as the original behavior) rather than
    /// being misstated as a 1:1 conversion.
    private let currencyConverter: CurrencyConverting?

    public init(currencyConverter: CurrencyConverting? = nil) {
        self.currencyConverter = currencyConverter
    }

    // MARK: - Core Daily Calculation

    /// Calculates the remaining daily budget considering active daily deductions and expenses recorded today.
    ///
    /// - Parameter context: The SwiftData `ModelContext` used for fetching active records.
    /// - Returns: The net remaining daily budget as a `Decimal`.
    /// - Throws: `FetchError` if database descriptor execution fails.
    public func calculateRemainingToday(context: ModelContext) throws -> Decimal {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }

        // 1. Fetch active global daily budget limit
        let budgetDescriptor = FetchDescriptor<SpendingLimit>(
            predicate: #Predicate { $0.isActive && $0.periodRawValue == "daily" }
        )
        let dailyBudgets = try context.fetch(budgetDescriptor)
        guard let dailyBudget = dailyBudgets.first else { return 0 }
        let targetCurrency = dailyBudget.currencyCode
        let baseLimit = dailyBudget.limitAmount

        // 2. Aggregate active recurring deductions (e.g., fixed recurring subscriptions/bills),
        //    converted into the daily budget's currency.
        let deductionDescriptor = FetchDescriptor<RecurringPayment>(predicate: #Predicate { $0.isActive })
        let activeDeductions = try context.fetch(deductionDescriptor)
        let totalDeductions = convertedTotal(
            activeDeductions.map { ($0.amount, $0.currencyCode) },
            into: targetCurrency
        )

        // 3. Fetch today's expense transactions
        // Edge Case Fix: Exclude non-expense types (.income, .transfer) and enforce half-open interval (< endOfDay)
        let recordDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.timestamp >= startOfDay && transaction.timestamp < endOfDay
            }
        )
        let todaysRecords = try context.fetch(recordDescriptor)

        let spentToday = convertedTotal(
            todaysRecords.filter { $0.type == .expense }.map { ($0.amount, $0.currencyCode) },
            into: targetCurrency
        )

        return baseLimit - totalDeductions - spentToday
    }

    // MARK: - General Budget Status Calculation

    /// Calculates total spent amount strictly for a given `SpendingLimit`.
    ///
    /// - Parameters:
    ///   - spendingLimit: The target budget limit configuration to evaluate.
    ///   - context: The SwiftData `ModelContext` used for database operations.
    /// - Returns: Sum total of matching expense transactions within the active window,
    ///   converted into the limit's own currency.
    public func calculateSpent(for spendingLimit: SpendingLimit, context: ModelContext) throws -> Decimal {
        try calculateSpentDetailed(for: spendingLimit, context: context).total
    }

    public struct SpentCalculation {
        public let total: Decimal
        /// Number of otherwise-matching expense transactions that could NOT
        /// be converted into the limit's currency (no converter configured,
        /// or no cached rate for that pair yet) and were therefore excluded
        /// from `total` rather than being misstated as a 1:1 conversion.
        /// Surface this in the UI if it's ever non-zero — it means the
        /// number the person is looking at is an undercount.
        public let unconvertedCount: Int
    }

    /// Same as `calculateSpent`, but also reports how many matching
    /// transactions couldn't be converted (and were therefore left out).
    public func calculateSpentDetailed(for spendingLimit: SpendingLimit, context: ModelContext) throws -> SpentCalculation {
        guard spendingLimit.isActive else { return SpentCalculation(total: 0, unconvertedCount: 0) }

        let calendar = Calendar.current
        let now = Date()

        let (startDate, endDate) = resolveDateInterval(for: spendingLimit, referenceDate: now, calendar: calendar)

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.timestamp >= startDate && transaction.timestamp < endDate
            }
        )
        let candidateRecords = try context.fetch(descriptor)
        let limitCurrency = spendingLimit.currencyCode

        let relevantRecords = candidateRecords.filter { record in
            // Edge Case 1: STRICT TYPE FILTERING
            guard record.type == .expense else { return false }

            // Edge Case 2: ACCOUNT SCOPING
            if let scopedAccount = spendingLimit.account {
                guard record.account.persistentModelID == scopedAccount.persistentModelID else { return false }
            }

            // Edge Case 3: EXPLICIT ASSIGNMENT — once a transaction is
            // explicitly pinned to a limit, it counts ONLY toward that one.
            // (This used to fall through to category/fallback matching for
            // *other* limits when the assignment didn't match, causing
            // double counting — fixed by returning unconditionally here.)
            if let assigned = record.spendingLimit {
                return assigned.persistentModelID == spendingLimit.persistentModelID
            }

            // Edge Case 4: CATEGORY SCOPING (multi-select — "any of")
            if !spendingLimit.categories.isEmpty {
                guard let recordCategory = record.category else { return false }
                return spendingLimit.categories.contains { $0.persistentModelID == recordCategory.persistentModelID }
            }

            // Edge Case 5: UNASSIGNED, UNCATEGORIZED FALLBACK — record.spendingLimit
            // is guaranteed nil at this point (handled above), and this limit
            // has no category filter, so it's a match.
            return true
        }

        var total = Decimal(0)
        var unconvertedCount = 0

        for record in relevantRecords {
            if record.currencyCode == limitCurrency {
                total += record.amount
                continue
            }
            if let converter = currencyConverter,
               let rate = converter.cachedRate(from: record.currencyCode, to: limitCurrency) {
                total += record.amount * rate
            } else {
                unconvertedCount += 1
            }
        }

        return SpentCalculation(total: total, unconvertedCount: unconvertedCount)
    }

    /// Calculates remaining allowable expenditure balance for any specific `SpendingLimit`.
    ///
    /// - Parameters:
    ///   - spendingLimit: The spending limit entity to calculate remaining balance for.
    ///   - context: The active SwiftData context.
    /// - Returns: Net remaining limit (`limitAmount - totalSpent`).
    public func calculateRemaining(for spendingLimit: SpendingLimit, context: ModelContext) throws -> Decimal {
        guard spendingLimit.isActive else { return 0 }
        let totalSpent = try calculateSpent(for: spendingLimit, context: context)
        return spendingLimit.limitAmount - totalSpent
    }

    // MARK: - Currency helpers

    private func convertedTotal(_ amounts: [(Decimal, String)], into targetCurrency: String) -> Decimal {
        amounts.reduce(Decimal(0)) { running, entry in
            let (amount, currency) = entry
            if currency == targetCurrency { return running + amount }
            guard let converter = currencyConverter,
                  let rate = converter.cachedRate(from: currency, to: targetCurrency) else {
                // No rate available yet — excluded rather than summed as if
                // it were the same currency.
                return running
            }
            return running + amount * rate
        }
    }

    // MARK: - Date Window Resolution

    /// Determines the exact start and end `Date` interval for a budget cycle reference.
    /// Uses half-open bounds: `startDate <= timestamp < endDate` to eliminate edge-case double counting at midnight.
    private func resolveDateInterval(
        for spendingLimit: SpendingLimit,
        referenceDate: Date,
        calendar: Calendar
    ) -> (startDate: Date, endDate: Date) {
        switch spendingLimit.period {
        case .daily:
            let start = calendar.startOfDay(for: referenceDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? referenceDate
            return (start, end)

        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? referenceDate
            return (start, end)

        case .quincena:
            // Semi-monthly boundaries: 1st-15th (ends at 16th 00:00:00), and 16th-End of Month (ends at 1st of next month 00:00:00)
            let day = calendar.component(.day, from: referenceDate)
            var components = calendar.dateComponents([.year, .month], from: referenceDate)

            if day <= 15 {
                // First Half: Day 1 (00:00:00) through Day 16 (00:00:00)
                components.day = 1
                let start = calendar.date(from: components) ?? referenceDate
                components.day = 16
                let end = calendar.date(from: components) ?? referenceDate
                return (start, end)
            } else {
                // Second Half: Day 16 (00:00:00) through Day 1 of Next Month (00:00:00)
                components.day = 16
                let start = calendar.date(from: components) ?? referenceDate

                components.day = 1
                let startOfCurrentMonth = calendar.date(from: components) ?? referenceDate
                let end = calendar.date(byAdding: .month, value: 1, to: startOfCurrentMonth) ?? referenceDate
                return (start, end)
            }

        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? referenceDate
            return (start, end)

        case .yearly:
            let components = calendar.dateComponents([.year], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: .year, value: 1, to: start) ?? referenceDate
            return (start, end)

        case .custom:
            // Reads explicit window properties stored on SpendingLimit
            let start = spendingLimit.startDate ?? referenceDate
            // Edge Case Fix: Ensure end date spans to end-of-day if custom limit end date is provided without time
            let rawEnd = spendingLimit.endDate ?? referenceDate
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: rawEnd)) ?? rawEnd
            return (start, end)
        }
    }
}
