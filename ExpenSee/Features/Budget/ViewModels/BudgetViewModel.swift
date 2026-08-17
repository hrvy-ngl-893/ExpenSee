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

    // Updates the current daily budget limit by ending any active rules and inserting a new one.
    func updateDailyLimit(context: ModelContext, newLimit: Decimal) {
        do {
            // 1. Fetch any currently active rules and deactivate them
            let descriptor = FetchDescriptor<DailyBudgetRule>(
                predicate: #Predicate<DailyBudgetRule> { $0.isCurrent == true }
            )
            let activeRules = try context.fetch(descriptor)

            for rule in activeRules {
                rule.isCurrent = false
            }

            // 2. Create the new current rule starting right now
            let newRule = DailyBudgetRule(
                baseDailyLimit: newLimit,
                effectiveFrom: Date(),
                isCurrent: true
            )

            context.insert(newRule)
            try context.save()

        } catch {
            print("Failed to update daily budget limit: \(error.localizedDescription)")
        }
    }   
    // Optional: Allow deleting historical rules to clean up the list
    func deleteRule(context: ModelContext, rule: DailyBudgetRule) {
        context.delete(rule)
        do {
            try context.save()
        } catch {
            print("Failed to delete budget rule: \(error.localizedDescription)")
        }
    }
}
