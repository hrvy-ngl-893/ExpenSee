//
//  AnalyticsViewModel.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData
import SwiftUI
import Observation
import ExpenSeeCore

public enum AnalyticsTimeframe: String, CaseIterable, Identifiable {
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
    
    public var id: String { rawValue }
    
    public func dateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let end = calendar.endOfDay(for: now) ?? now
        
        let start: Date
        switch self {
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        return (calendar.startOfDay(for: start), end)
    }
}

@Observable
@MainActor
public final class AnalyticsViewModel {
    public struct TrendPoint: Identifiable {
        public let id = UUID()
        public let date: Date
        public let totalAmount: Double
    }
    
    public struct CategorySummary: Identifiable {
        public let id = UUID()
        public let category: SpendingCategory
        public let totalAmount: Double
        public let percentage: Double
    }
    
    @ObservationIgnored
    private let aggregator = AnalyticsAggregator()
    
    public var timeframe: AnalyticsTimeframe = .month
    public var categorySummaries: [CategorySummary] = []
    public var sourceSpending: [String: Decimal] = [:]
    public var dailyTrend: [TrendPoint] = []
    public var biggestTransactionsList: [ExpenSeeCore.Transaction] = []
    public var totalSpent: Decimal = 0
    public var averageDailySpend: Decimal = 0
    
    public init() {}
    
    public func loadData(context: ModelContext) {
        let range = timeframe.dateRange()
        do {
            let rawCategoryDict = try aggregator.totalSpentByCategory(context: context, from: range.start, to: range.end)
            let grandTotalDecimal = try aggregator.totalSpent(context: context, from: range.start, to: range.end)
            let grandTotalDouble = NSDecimalNumber(decimal: grandTotalDecimal).doubleValue
            
            let allCategories = try context.fetch(FetchDescriptor<SpendingCategory>())
            let categoryMap = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.name, $0) })
            
            var summaries: [CategorySummary] = []
            for (name, amountDecimal) in rawCategoryDict {
                let amountDouble = NSDecimalNumber(decimal: amountDecimal).doubleValue
                let percentage = grandTotalDouble > 0 ? (amountDouble / grandTotalDouble) * 100 : 0
                
                let categoryEntity = categoryMap[name] ?? SpendingCategory(name: name, hexColor: "888888", iconString: "questionmark.circle")
                
                summaries.append(
                    CategorySummary(
                        category: categoryEntity,
                        totalAmount: amountDouble,
                        percentage: percentage
                    )
                )
            }
            self.categorySummaries = summaries.sorted { $0.totalAmount > $1.totalAmount }
            
            self.sourceSpending = try aggregator.totalSpentBySource(context: context, from: range.start, to: range.end)
            
            let rawTrend = try aggregator.dailySpendingTrend(context: context, from: range.start, to: range.end)
            self.dailyTrend = rawTrend.map { item in
                TrendPoint(
                    date: item.date,
                    totalAmount: NSDecimalNumber(decimal: item.amount).doubleValue
                )
            }
            
            self.biggestTransactionsList = try aggregator.biggestExpenses(context: context, from: range.start, to: range.end, limit: 5)
            self.totalSpent = grandTotalDecimal
            self.averageDailySpend = try aggregator.averageDailySpend(context: context, from: range.start, to: range.end)
            
        } catch {
            print("Failed to load analytics data: \(error.localizedDescription)")
        }
    }
}

extension Calendar {
    fileprivate func endOfDay(for date: Date) -> Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: self.startOfDay(for: date))
    }
}
