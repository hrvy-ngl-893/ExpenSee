//
//  SpendingLimitViewModel.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//
//  CHANGES FROM ORIGINAL:
//  1. `category: SpendingCategory?` -> the model's `categories` is now
//     `[SpendingCategory]`. Kept this view model's public parameter as a
//     single optional `category` (didn't want to force a rewrite of an
//     unseen picker UI you haven't shared) and just wrap it into a 0-or-1
//     element array internally. When you build a multi-select category
//     picker, swap these params for `categories: [SpendingCategory] = []`
//     and pass straight through — no other logic needs to change.
//  2. FIXED ORDERING BUG: `currencyCode` is now derived live from `account`
//     on SpendingLimit. The original code did
//         existingLimit.currencyCode = account?.currencyCode ?? currencyCode
//         existingLimit.account = account
//     — setting currencyCode BEFORE account meant the currencyCode setter
//     saw the *old* account value. Editing an already account-scoped limit
//     would hit the model's DEBUG assertion (and silently no-op in
//     release) even though nothing was actually wrong. Fixed by setting
//     `account` first, and only touching `currencyCode` directly when
//     `account == nil` (account-scoped limits derive it automatically —
//     manually setting it is meaningless once an account is attached).
//

import Foundation
import SwiftData
import SwiftUI
import ExpenSeeCore

@Observable
@MainActor
final class SpendingLimitViewModel {

    /// Creates or updates a standard period budget (Daily, Weekly, Monthly).
    /// `currencyCode` is required — no default — so callers are forced to
    /// pick a currency explicitly rather than silently inheriting "USD".
    /// Pass `account` to scope this limit to one account (currency is then
    /// taken from the account); pass nil for a currency-wide limit spanning
    /// all accounts in that currency.
    func saveStandardSpendingLimit(
        context: ModelContext,
        period: RecurrenceFrequency,
        limitAmount: Decimal,
        currencyCode: String,
        account: Account? = nil,
        category: SpendingCategory? = nil,
        name: String? = nil,
        existingLimit: SpendingLimit? = nil
    ) {
        do {
            if let existingLimit {
                existingLimit.name = (name?.isEmpty == false) ? name! : "\(period.rawValue.capitalized) Budget"
                existingLimit.limitAmount = limitAmount

                // Set account FIRST — currencyCode derives from it once set,
                // and only needs a manual value for account-less limits.
                existingLimit.account = account
                if account == nil {
                    existingLimit.currencyCode = currencyCode
                }

                existingLimit.categories = category.map { [$0] } ?? []
                existingLimit.isActive = true
            } else {
                let rawPeriod = period.rawValue
                let descriptor = FetchDescriptor<SpendingLimit>(
                    predicate: #Predicate<SpendingLimit> { $0.isActive && $0.periodRawValue == rawPeriod }
                )
                let activeBudgets = try context.fetch(descriptor)
                let resolvedCurrency = account?.currencyCode ?? currencyCode
                for budget in activeBudgets where budget.currencyCode == resolvedCurrency {
                    budget.isActive = false
                }

                let budgetName = (name?.isEmpty == false) ? name! : "\(period.rawValue.capitalized) Budget"
                let newBudget = SpendingLimit(
                    name: budgetName,
                    limitAmount: limitAmount,
                    currencyCode: currencyCode,
                    period: period,
                    startDate: Date(),
                    isActive: true,
                    account: account,
                    categories: category.map { [$0] } ?? []
                )
                context.insert(newBudget)
            }
            try context.save()
        } catch {
            print("Failed to save standard budget: \(error.localizedDescription)")
        }
    }

    /// Creates a custom or category-assignable budget. Supply either
    /// `currencyCode` or `account` (or both, as long as they agree) — the
    /// model will assert in DEBUG if neither is given.
    func createAssignableSpendingLimit(
        context: ModelContext,
        name: String,
        limitAmount: Decimal,
        currencyCode: String? = nil,
        account: Account? = nil,
        startDate: Date,
        endDate: Date?,
        repeatFrequency: RecurrenceFrequency?,
        category: SpendingCategory?
    ) {
        let assignableBudget = SpendingLimit(
            name: name.isEmpty ? "Custom Budget" : name,
            limitAmount: limitAmount,
            currencyCode: currencyCode,
            period: .custom,
            startDate: startDate,
            endDate: endDate,
            repeatFrequency: repeatFrequency,
            isActive: true,
            account: account,
            categories: category.map { [$0] } ?? []
        )

        context.insert(assignableBudget)

        do {
            try context.save()
        } catch {
            print("Failed to create assignable budget: \(error.localizedDescription)")
        }
    }

    /// Updates an existing custom or category-assignable budget.
    /// NOTE: changing currency/account on a budget that already has
    /// transactions attached means those older transactions may no longer
    /// match (calculateRemaining filters by currency/account, converting
    /// where a cached exchange rate exists), so their spend can shift in or
    /// out of this limit's totals. That's intentional — mixing currencies
    /// silently is the bug we're avoiding — but worth surfacing to the user
    /// in the edit UI if they change it.
    func updateAssignableSpendingLimit(
        context: ModelContext,
        spendingLimit: SpendingLimit,
        name: String,
        limitAmount: Decimal,
        currencyCode: String? = nil,
        account: Account? = nil,
        startDate: Date,
        endDate: Date?,
        repeatFrequency: RecurrenceFrequency?,
        category: SpendingCategory?
    ) {
        spendingLimit.name = name.isEmpty ? "Custom Budget" : name
        spendingLimit.limitAmount = limitAmount

        // Same ordering fix as above: account first, currencyCode only
        // matters (and is only settable) when going account-less.
        spendingLimit.account = account
        if account == nil, let currencyCode {
            spendingLimit.currencyCode = currencyCode
        }

        spendingLimit.startDate = startDate
        spendingLimit.endDate = endDate
        spendingLimit.repeatFrequency = repeatFrequency
        spendingLimit.categories = category.map { [$0] } ?? []

        do {
            try context.save()
        } catch {
            print("Failed to update assignable budget: \(error.localizedDescription)")
        }
    }

    /// Deletes or deactivates a budget entry
    func deleteSpendingLimit(context: ModelContext, spendingLimit: SpendingLimit) {
        context.delete(spendingLimit)
        do {
            try context.save()
        } catch {
            print("Failed to delete budget: \(error.localizedDescription)")
        }
    }
}
