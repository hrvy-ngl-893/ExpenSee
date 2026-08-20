//
//  DashboardViewModel.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//
//  CHANGE FROM ORIGINAL:
//  `budgetEngine` used to be `= BudgetEngine()`, hardcoded with no currency
//  converter — a separate instance from the one SpendingRepository builds.
//  Once you wire up a real CurrencyConverting (SwiftDataCurrencyConverter),
//  every BudgetEngine instance in the app needs to share it, or the
//  dashboard and the widget/Live Activity can disagree on totals whenever
//  a limit has cross-currency transactions. Made it injectable — construct
//  one BudgetEngine(currencyConverter:) at app startup and pass it to both
//  this and SpendingRepository.
//
//  ALSO WORTH DECIDING: SpendingLimitViewModel's dedup logic lets multiple
//  active *daily* limits coexist as long as they're in different
//  currencies, but BudgetEngine.calculateRemainingToday (used by
//  getRemainingBudget/the widget) just grabs the first active daily limit
//  it finds — no currency preference, order not guaranteed. Once more than
//  one currency has an active daily limit, that "first" pick is arbitrary.
//  Two ways out: point the widget/Live Activity at featuredSpendingLimit
//  via calculateRemaining(for:) (already currency-safe) instead of the
//  global daily helper, or make daily limits exclusive across currencies
//  too. Not fixed here since it's a product decision, not a bug fix.
//

import Foundation
import SwiftUI
import SwiftData
import ExpenSeeCore
#if os(iOS) && canImport(ActivityKit)
import ActivityKit
#endif

@Observable
@MainActor
final class DashboardViewModel {

    private let budgetEngine: BudgetEngine

    init(budgetEngine: BudgetEngine = BudgetEngine()) {
        self.budgetEngine = budgetEngine
    }

    // MARK: - Featured Limit Selection

    func featuredSpendingLimit(from activeLimits: [SpendingLimit], selectedIDString: String) -> SpendingLimit? {
        if !selectedIDString.isEmpty,
           let matched = activeLimits.first(where: { String(describing: $0.persistentModelID) == selectedIDString }) {
            return matched
        }

        // Priority fallbacks
        if let daily = activeLimits.first(where: { $0.period == .daily }) { return daily }
        if let weekly = activeLimits.first(where: { $0.period == .weekly }) { return weekly }
        if let quincena = activeLimits.first(where: { $0.period == .quincena }) { return quincena }
        if let monthly = activeLimits.first(where: { $0.period == .monthly }) { return monthly }
        if let yearly = activeLimits.first(where: { $0.period == .yearly }) { return yearly }

        return activeLimits.first
    }

    // MARK: - Remaining / Spent

    /// Delegates to BudgetEngine so this is the single source of truth for
    /// "what's left on this limit" — no duplicate currency-blind logic here.
    /// `spent` is derived (limitAmount - remaining) rather than recomputed,
    /// so it can never drift from what BudgetEngine actually counted.
    func remainingAndSpent(for spendingLimit: SpendingLimit, context: ModelContext) -> (remaining: Decimal, spent: Decimal) {
        do {
            let remaining = try budgetEngine.calculateRemaining(for: spendingLimit, context: context)
            let spent = spendingLimit.limitAmount - remaining
            return (remaining, spent)
        } catch {
            print("Failed to calculate remaining for '\(spendingLimit.name)': \(error.localizedDescription)")
            return (spendingLimit.limitAmount, 0)
        }
    }

    func progressRatio(remaining: Decimal, limit: Decimal) -> Double {
        let limitDouble = NSDecimalNumber(decimal: limit).doubleValue
        let remainingDouble = NSDecimalNumber(decimal: remaining).doubleValue
        guard limitDouble > 0 else { return 0 }
        return min(max(remainingDouble / limitDouble, 0), 1)
    }

    func statusColor(remaining: Decimal, ratio: Double) -> Color {
        if remaining < 0 { return .red }
        if ratio < 0.2 { return .orange }
        return .green
    }

    // MARK: - Live Activity

    #if os(iOS) && canImport(ActivityKit)
    func isLiveActivityActive() -> Bool {
        LiveActivityManager.shared.currentActivity != nil
    }

    func endLiveActivity() {
        LiveActivityManager.shared.endActivity()
    }


    /// Starts/updates the Live Activity for `spendingLimit`. The "last
    /// expense" shown alongside the remaining amount is scoped to the same
    /// currency (and account, if the limit is account-scoped) as the limit
    /// itself — otherwise a transaction in a different currency could be
    /// surfaced next to a remaining-amount figure it was never counted
    /// against, which is the same class of bug as the summing issue.
    func startOrUpdateLiveActivity(
        for spendingLimit: SpendingLimit,
        context: ModelContext,
        todaysTransactions: [ExpenSeeCore.Transaction],
        currencyCode: String
    ) {
        let (remaining, spent) = remainingAndSpent(for: spendingLimit, context: context)

        let lastRecord = todaysTransactions
            .filter { transaction in
                guard transaction.currencyCode == spendingLimit.currencyCode else { return false }
                if let scopedAccount = spendingLimit.account {
                    return transaction.account.persistentModelID == scopedAccount.persistentModelID
                }
                return true
            }
            .sorted(by: { $0.timestamp > $1.timestamp })
            .first

        LiveActivityManager.shared.updateOrStartActivity(
            remainingBudget: remaining,
            spentToday: spent,
            baseDailyLimit: spendingLimit.limitAmount,
            budgetCycleName: spendingLimit.name,
            currencyCode: currencyCode,
            lastExpenseAmount: lastRecord?.amount,
            lastExpenseCategory: lastRecord?.category?.name
        )
    }
    #endif
}
