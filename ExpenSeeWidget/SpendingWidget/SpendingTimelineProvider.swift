//
//  SpendingTimelineProvider.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import WidgetKit
import SwiftUI
import SwiftData
import ExpenSeeCore

struct SpendingEntry: TimelineEntry {
    let date: Date
    let spendingLimit: Decimal
    let spent: Decimal
    let configuration: ConfigurationAppIntent
    let currencyCode: String
    let iconString: String?
    var name: String
}

@MainActor
struct SpendingTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = SpendingEntry
    typealias Intent = ConfigurationAppIntent

    func placeholder(in context: Context) -> SpendingEntry {
        SpendingEntry(
            date: Date(),
            spendingLimit: 100.00,
            spent: 57.50,
            configuration: ConfigurationAppIntent(),
            currencyCode: Locale.current.currency?.identifier ?? "USD",
            iconString: "creditcard.fill",
            name: "Daily"
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SpendingEntry {
        fetchCurrentBudgetEntry(configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SpendingEntry> {
        let entry = fetchCurrentBudgetEntry(configuration: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchCurrentBudgetEntry(configuration: ConfigurationAppIntent) -> SpendingEntry {
        let container = ModelContainerFactory.shared
        let context = ModelContext(container)
        let budgetEngine = BudgetEngine()
        
        do {
            var selectedBudget: SpendingLimit?
            
            // 1. Fetch the specific budget chosen by the user in the widget edit screen
            if let targetEntity = configuration.selectedBudget,
               let targetUUID = UUID(uuidString: targetEntity.id) {
                let descriptor = FetchDescriptor<SpendingLimit>(
                    predicate: #Predicate<SpendingLimit> { $0.id == targetUUID && $0.isActive }
                )
                selectedBudget = try context.fetch(descriptor).first
            }
            
            // 2. Fallback to active daily budget if no budget was selected or if the selected one was deleted
            if selectedBudget == nil {
                let dailyPeriodRaw = RecurrenceFrequency.daily.rawValue
                var fallbackDescriptor = FetchDescriptor<SpendingLimit>(
                    predicate: #Predicate<SpendingLimit> { $0.isActive && $0.periodRawValue == dailyPeriodRaw }
                )
                fallbackDescriptor.fetchLimit = 1
                selectedBudget = try context.fetch(fallbackDescriptor).first
            }

            guard let budget = selectedBudget else {
                return emptyFallbackEntry(configuration: configuration)
            }

            // 3. Compute limits and total spent using BudgetEngine for the chosen budget
            let limitAmount = budget.limitAmount
            let remaining = try budgetEngine.calculateRemaining(for: budget, context: context)
            let totalSpent = limitAmount - remaining

            // Resolved Icon: Safe check for array-based categories with fallbacks
            let resolvedIcon = budget.categories.first?.iconString
                ?? budget.account?.iconString
                ?? "creditcard.fill"

            return SpendingEntry(
                date: Date(),
                spendingLimit: limitAmount,
                spent: max(0, totalSpent),
                configuration: configuration,
                currencyCode: budget.currencyCode,
                iconString: resolvedIcon,
                name: budget.name
            )
        } catch {
            return emptyFallbackEntry(configuration: configuration)
        }
    }

    private func emptyFallbackEntry(configuration: ConfigurationAppIntent) -> SpendingEntry {
        SpendingEntry(
            date: Date(),
            spendingLimit: 0,
            spent: 0,
            configuration: configuration,
            currencyCode: Locale.current.currency?.identifier ?? "USD",
            iconString: "creditcard.fill",
            name: "No Budget"
        )
    }
}
