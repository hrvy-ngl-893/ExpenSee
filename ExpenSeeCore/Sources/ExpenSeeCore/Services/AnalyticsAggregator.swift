//
//  AnalyticsAggregator.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

public struct AnalyticsAggregator {
    public init() {}
    
    // 1. Total spent by category (Pie/Donut Charts)
    public func totalSpentByCategory(context: ModelContext, from startDate: Date, to endDate: Date) throws -> [String: Decimal] {
        let records = try fetchRecords(context: context, from: startDate, to: endDate)
        var totals: [String: Decimal] = [:]
        
        for record in records {
            let catName = record.category?.name ?? "Uncategorized"
            totals[catName, default: 0] += record.amount
        }
        return totals
    }
    
    // 2. Total spent by funding source (e.g., Credit Card vs Cash)
    public func totalSpentBySource(context: ModelContext, from startDate: Date, to endDate: Date) throws -> [String: Decimal] {
        let records = try fetchRecords(context: context, from: startDate, to: endDate)
        var totals: [String: Decimal] = [:]
        
        for record in records {
            let accountName = record.account.name
            totals[accountName, default: 0] += record.amount
        }
        return totals
    }
    
    // 3. Daily spending trend (Time-series Line/Bar Charts)
    public func dailySpendingTrend(context: ModelContext, from startDate: Date, to endDate: Date) throws -> [(date: Date, amount: Decimal)] {
        let records = try fetchRecords(context: context, from: startDate, to: endDate)
        let calendar = Calendar.current
        var dailyTotals: [Date: Decimal] = [:]
        
        for record in records {
            let startOfDay = calendar.startOfDay(for: record.timestamp)
            dailyTotals[startOfDay, default: 0] += record.amount
        }
        
        // Return sorted chronologically for chart plotting
        return dailyTotals.map { (date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    // 4. Biggest individual expenses (Top N list)
    public func biggestExpenses(context: ModelContext, from startDate: Date, to endDate: Date, limit: Int = 5) throws -> [Transaction] {
        let records = try fetchRecords(context: context, from: startDate, to: endDate)
        return Array(records.sorted(by: { $0.amount > $1.amount }).prefix(limit))
    }
    
    // 5. Grand total for a period
    public func totalSpent(context: ModelContext, from startDate: Date, to endDate: Date) throws -> Decimal {
        let records = try fetchRecords(context: context, from: startDate, to: endDate)
        return records.reduce(0) { $0 + $1.amount }
    }
    
    // 6. Average daily spend
    public func averageDailySpend(context: ModelContext, from startDate: Date, to endDate: Date) throws -> Decimal {
        let total = try totalSpent(context: context, from: startDate, to: endDate)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: endDate))
        
        // Add 1 to ensure inclusive counting (e.g., today to today = 1 day)
        let days = max(1, (components.day ?? 0) + 1)
        
        return total / Decimal(days)
    }
    
    // Helper to safely fetch and filter dates in memory to avoid SwiftData predicate quirks
    private func fetchRecords(context: ModelContext, from startDate: Date, to endDate: Date) throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>()
        let allRecords = try context.fetch(descriptor)
        return allRecords.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
}
