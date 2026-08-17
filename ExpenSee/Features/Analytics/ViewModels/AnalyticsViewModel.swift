//
//  AnalyticsViewModel.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine
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

@MainActor
public final class AnalyticsViewModel: ObservableObject {
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
    
    private let aggregator = AnalyticsAggregator()
    
    @Published public var timeframe: AnalyticsTimeframe = .month
    @Published public var categorySummaries: [CategorySummary] = []
    @Published public var sourceSpending: [String: Decimal] = [:]
    @Published public var dailyTrend: [TrendPoint] = []
    @Published public var biggestExpensesList: [SpendingRecord] = []
    @Published public var totalSpent: Decimal = 0
    @Published public var averageDailySpend: Decimal = 0
    
    public init() {}
    
    public func loadData(context: ModelContext) {
        let range = timeframe.dateRange()
        do {
            // 1. Fetch raw category dict and match with actual category entities if possible
            let rawCategoryDict = try aggregator.totalSpentByCategory(context: context, from: range.start, to: range.end)
            let grandTotalDecimal = try aggregator.totalSpent(context: context, from: range.start, to: range.end)
            let grandTotalDouble = NSDecimalNumber(decimal: grandTotalDecimal).doubleValue
            
            // Fetch all categories to map names to actual SpendingCategory objects
            let allCategories = try context.fetch(FetchDescriptor<SpendingCategory>())
            let categoryMap = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.name, $0) })
            
            var summaries: [CategorySummary] = []
            for (name, amountDecimal) in rawCategoryDict {
                let amountDouble = NSDecimalNumber(decimal: amountDecimal).doubleValue
                let percentage = grandTotalDouble > 0 ? (amountDouble / grandTotalDouble) * 100 : 0
                
                // Fallback dummy category if it's "Uncategorized" or missing from DB
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
            
            // 2. Source Spending
            self.sourceSpending = try aggregator.totalSpentBySource(context: context, from: range.start, to: range.end)
            
            // 3. Daily Trend
            let rawTrend = try aggregator.dailySpendingTrend(context: context, from: range.start, to: range.end)
            self.dailyTrend = rawTrend.map { item in
                TrendPoint(
                    date: item.date,
                    totalAmount: NSDecimalNumber(decimal: item.amount).doubleValue
                )
            }
            
            // 4. Miscellaneous metrics
            self.biggestExpensesList = try aggregator.biggestExpenses(context: context, from: range.start, to: range.end, limit: 5)
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
