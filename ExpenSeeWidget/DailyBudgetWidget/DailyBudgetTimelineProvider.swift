//
//  DailyBudgetTimelineProvider.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import WidgetKit
import SwiftUI
import SwiftData
import ExpenSeeCore

struct DailyBudgetEntry: TimelineEntry {
    let date: Date
    let remainingBudget: Decimal
    let baseDailyLimit: Decimal
    let spentToday: Decimal
    let configuration: ConfigurationAppIntent
}

struct DailyBudgetTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = DailyBudgetEntry
    typealias Intent = ConfigurationAppIntent

    func placeholder(in context: Context) -> DailyBudgetEntry {
        DailyBudgetEntry(
            date: Date(),
            remainingBudget: 42.50,
            baseDailyLimit: 100.00,
            spentToday: 57.50,
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> DailyBudgetEntry {
        fetchCurrentBudgetEntry(configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<DailyBudgetEntry> {
        let entry = fetchCurrentBudgetEntry(configuration: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchCurrentBudgetEntry(configuration: ConfigurationAppIntent) -> DailyBudgetEntry {
        let container = ModelContainerFactory.shared
        let context = ModelContext(container)
        let budgetEngine = BudgetEngine()
        
        do {
            let remaining = try budgetEngine.calculateRemainingToday(context: context)
            
            var ruleDescriptor = FetchDescriptor<DailyBudgetRule>(predicate: #Predicate { $0.isCurrent })
            ruleDescriptor.fetchLimit = 1
            let baseLimit = try context.fetch(ruleDescriptor).first?.baseDailyLimit ?? 0
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            let records = try context.fetch(FetchDescriptor<SpendingRecord>())
            let spentToday = records
                .filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
                .reduce(Decimal(0)) { $0 + $1.amount }
            
            return DailyBudgetEntry(
                date: Date(),
                remainingBudget: remaining,
                baseDailyLimit: baseLimit,
                spentToday: spentToday,
                configuration: configuration
            )
        } catch {
            return DailyBudgetEntry(
                date: Date(),
                remainingBudget: 0,
                baseDailyLimit: 0,
                spentToday: 0,
                configuration: configuration
            )
        }
    }
}
