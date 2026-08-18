//
//  BudgetViewModel.swift
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
final class BudgetViewModel {

    /// Creates or updates a standard period budget (Daily, Weekly, Monthly)
    func saveStandardBudget(
        context: ModelContext,
        period: BudgetPeriod,
        limitAmount: Decimal,
        existingBudget: Budget? = nil
    ) {
        do {
            if let existingBudget {
                existingBudget.limitAmount = limitAmount
                existingBudget.isActive = true
            } else {
                // Deactivate prior standard budgets for the same period
                let rawPeriod = period.rawValue
                let descriptor = FetchDescriptor<Budget>(
                    predicate: #Predicate<Budget> { $0.isActive && $0.periodRawValue == rawPeriod }
                )
                let activeBudgets = try context.fetch(descriptor)
                for budget in activeBudgets {
                    budget.isActive = false
                }

                let newBudget = Budget(
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
    func createAssignableBudget(
        context: ModelContext,
        name: String,
        limitAmount: Decimal,
        startDate: Date,
        endDate: Date?,
        repeatFrequency: PaymentFrequency?,
        category: SpendingCategory?
    ) {
        let assignableBudget = Budget(
            name: name.isEmpty ? "Custom Budget" : name,
            limitAmount: limitAmount,
            period: .assignable,
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
    func updateAssignableBudget(
        context: ModelContext,
        budget: Budget,
        name: String,
        limitAmount: Decimal,
        startDate: Date,
        endDate: Date?,
        repeatFrequency: PaymentFrequency?,
        category: SpendingCategory?
    ) {
        budget.name = name.isEmpty ? "Custom Budget" : name
        budget.limitAmount = limitAmount
        budget.startDate = startDate
        budget.endDate = endDate
        budget.repeatFrequency = repeatFrequency
        budget.category = category
        
        do {
            try context.save()
        } catch {
            print("Failed to update assignable budget: \(error.localizedDescription)")
        }
    }

    /// Deletes or deactivates a budget entry
    func deleteBudget(context: ModelContext, budget: Budget) {
        context.delete(budget)
        do {
            try context.save()
        } catch {
            print("Failed to delete budget: \(error.localizedDescription)")
        }
    }
}
