//
//  SpendingLimitViewModel.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData
import SwiftUI
import ExpenSeeCore

@Observable
@MainActor
final class SpendingLimitViewModel {

    /// Creates or updates a standard period budget (Daily, Weekly, Monthly)
    func saveStandardSpendingLimit(
        context: ModelContext,
        period: RecurrenceFrequency,
        limitAmount: Decimal,
        existingLimit: SpendingLimit? = nil
    ) {
        do {
            if let existingLimit {
                existingLimit.limitAmount = limitAmount
                existingLimit.isActive = true
            } else {
                // Deactivate prior standard budgets for the same period
                let rawPeriod = period.rawValue
                let descriptor = FetchDescriptor<SpendingLimit>(
                    predicate: #Predicate<SpendingLimit> { $0.isActive && $0.periodRawValue == rawPeriod }
                )
                let activeBudgets = try context.fetch(descriptor)
                for budget in activeBudgets {
                    budget.isActive = false
                }

                let newBudget = SpendingLimit(
                    name: "\(period.rawValue.capitalized) Budget",
                    limitAmount: limitAmount,
                    period: period,
                    startDate: Date(),
                    isActive: true
                )
                context.insert(newBudget)
            }
            try context.save()
        } catch {
            print("Failed to save standard budget: \(error.localizedDescription)")
        }
    }

    /// Creates a custom or category-assignable budget
    func createAssignableSpendingLimit(
        context: ModelContext,
        name: String,
        limitAmount: Decimal,
        startDate: Date,
        endDate: Date?,
        repeatFrequency: RecurrenceFrequency?,
        category: SpendingCategory?
    ) {
        let assignableBudget = SpendingLimit(
            name: name.isEmpty ? "Custom Budget" : name,
            limitAmount: limitAmount,
            period: .custom,
            startDate: startDate,
            endDate: endDate,
            repeatFrequency: repeatFrequency,
            isActive: true,
            category: category
        )
        
        context.insert(assignableBudget)
        
        do {
            try context.save()
        } catch {
            print("Failed to create assignable budget: \(error.localizedDescription)")
        }
    }

    /// Updates an existing custom or category-assignable budget
    func updateAssignableSpendingLimit(
        context: ModelContext,
        spendingLimit: SpendingLimit,
        name: String,
        limitAmount: Decimal,
        startDate: Date,
        endDate: Date?,
        repeatFrequency: RecurrenceFrequency?,
        category: SpendingCategory?
    ) {
        spendingLimit.name = name.isEmpty ? "Custom Budget" : name
        spendingLimit.limitAmount = limitAmount
        spendingLimit.startDate = startDate
        spendingLimit.endDate = endDate
        spendingLimit.repeatFrequency = repeatFrequency
        spendingLimit.category = category
        
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
