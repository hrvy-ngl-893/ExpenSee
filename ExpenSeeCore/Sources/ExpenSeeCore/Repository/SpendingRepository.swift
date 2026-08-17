//
//   SpendingRepository.swift
//   ExpenSee
//
//   Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
public class SpendingRepository {
    private let context: ModelContext
    private let budgetEngine: BudgetEngine
    
    public init(context: ModelContext) {
        self.context = context
        self.budgetEngine = BudgetEngine()
    }
    
    /// Creates and persists a new SpendingCategory.
    @discardableResult
    public func createCategory(name: String, hexColor: String = "#007AFF", iconString: String = "cart") throws -> SpendingCategory {
        let category = SpendingCategory(
            name: name,
            hexColor: hexColor,
            iconString: iconString
        )
        context.insert(category)
        try context.save()
        return category
    }
    
    public func logSpending(amount: Decimal, category: SpendingCategory?, source: MoneySource?, note: String = "") throws {
        let record = SpendingRecord(
            amount: amount,
            note: note,
            category: category,
            source: source
        )
        
        context.insert(record)
        try context.save()
        
        Task {
            await refreshExtensions()
        }
    }
    
    public func delete(record: SpendingRecord) throws {
        context.delete(record)
        try context.save()
        
        Task {
            await refreshExtensions()
        }
    }
    
    public func getRemainingBudget() throws -> Decimal {
        return try budgetEngine.calculateRemainingToday(context: context)
    }
    
    private func refreshExtensions() async {
        WidgetCenter.shared.reloadAllTimelines()
        
        #if os(iOS)
        do {
            let remainingDecimal = try getRemainingBudget()
            let remaining = NSDecimalNumber(decimal: remainingDecimal).doubleValue
            let spentTodayDecimal = try calculateSpentToday()
            let spentToday = NSDecimalNumber(decimal: spentTodayDecimal).doubleValue
            
            if #available(iOS 16.2, *) {
                let updatedState = SpendingActivityAttributes.ContentState(
                    remainingBudget: remaining,
                    spentToday: spentToday
                )
                
                for activity in Activity<SpendingActivityAttributes>.activities {
                    let content = ActivityContent(state: updatedState, staleDate: nil)
                    await activity.update(content)
                }
            }
        } catch {
            print("Failed to fetch budget for Live Activity update: \(error.localizedDescription)")
        }
        #endif
    }
    
    private func calculateSpentToday() throws -> Decimal {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }
        
        let records = try context.fetch(FetchDescriptor<SpendingRecord>())
        let todaysRecords = records.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
        return todaysRecords.reduce(Decimal(0)) { $0 + $1.amount }
    }
}
