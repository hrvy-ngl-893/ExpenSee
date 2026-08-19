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
            let remaining = try budgetEngine.calculateRemainingToday(context: context)
            
            let dailyPeriodRaw = RecurrenceFrequency.daily.rawValue
            var budgetDescriptor = FetchDescriptor<SpendingLimit>(
                predicate: #Predicate<SpendingLimit> { $0.isActive && $0.periodRawValue == dailyPeriodRaw }
            )
            budgetDescriptor.fetchLimit = 1
            let currentBudget = try context.fetch(budgetDescriptor).first
            
            let limitAmount = currentBudget?.limitAmount ?? 0
            let cycleName = currentBudget?.name ?? "Daily"
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            let records = try context.fetch(FetchDescriptor<ExpenSeeCore.Transaction>())
            let spentToday = records.reduce(Decimal(0)) { $0 + $1.amount }
            
            return SpendingEntry(
                date: Date(),
                spendingLimit: limitAmount,
                spent: spentToday,
                configuration: configuration,
                name: cycleName
            )
        } catch {
            return SpendingEntry(
                date: Date(),
                spendingLimit: 0,
                spent: 0,
                configuration: configuration,
                name: "Daily"
            )
        }
    }
}
