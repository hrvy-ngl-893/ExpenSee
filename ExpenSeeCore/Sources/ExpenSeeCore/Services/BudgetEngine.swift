//
//  BudgetEngine.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//


import Foundation
import SwiftData

public struct BudgetEngine {
    
    public init() {}
    
    // MARK: - Core Daily Calculation
    
    /// Calculates the remaining daily budget considering deductions and expenses recorded today.
    public func calculateRemainingToday(context: ModelContext) throws -> Decimal {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }
        
        // 1. Fetch active global daily budget
        let budgetDescriptor = FetchDescriptor<SpendingLimit>(
            predicate: #Predicate { $0.isActive && $0.periodRawValue == "daily" }
        )
        let dailyBudgets = try context.fetch(budgetDescriptor)
        let baseLimit = dailyBudgets.first?.limitAmount ?? 0
        
        // 2. Subtract active deductions
        let deductionDescriptor = FetchDescriptor<RecurringPayment>(predicate: #Predicate { $0.isActive })
        let activeDeductions = try context.fetch(deductionDescriptor)
        let totalDeductions = activeDeductions.reduce(into: Decimal(0)) { $0 + $1.amount }
        
        // 3. Subtract today's total spending records
        let records = try context.fetch(FetchDescriptor<Transaction>())
        let todaysRecords = records.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
        let spentToday = todaysRecords.reduce(Decimal(0)) { $0 + $1.amount }
        
        return baseLimit - totalDeductions - spentToday
    }
    
    // MARK: - General Budget Status Calculation
    
    /// Calculates remaining amount for any specific Budget instance (Daily, Weekly, Monthly, or Assignable).
    public func calculateRemaining(for spendingLimit: SpendingLimit, context: ModelContext) throws -> Decimal {
        guard spendingLimit.isActive else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        
        let (startDate, endDate) = resolveDateInterval(for: spendingLimit, referenceDate: now, calendar: calendar)
        
        // Fetch all relevant expenses matching date range, optional category, or explicit budget attachment
        let records = try context.fetch(FetchDescriptor<Transaction>())
        let relevantRecords = records.filter { record in
            guard record.timestamp >= startDate && record.timestamp <= endDate else { return false }
            
            // If explicitly attached to this budget, count it
            if let assignedBudget = record.spendingLimit, assignedBudget.id == spendingLimit.id {
                return true
            }
            
            // If budget is assigned to a specific category, match by category
            if let targetCategory = spendingLimit.category {
                return record.category?.id == targetCategory.id
            }
            
            // Otherwise, apply to unassigned global period budgets
            return record.spendingLimit == nil
        }
        
        let totalSpent = relevantRecords.reduce(Decimal(0)) { $0 + $1.amount }
        return spendingLimit.limitAmount - totalSpent
    }
    
    // MARK: - Helper Methods
    
    private func resolveDateInterval(for spendingLimit: SpendingLimit, referenceDate: Date, calendar: Calendar) -> (Date, Date) {
        switch spendingLimit.period {
        case .daily:
            let start = calendar.startOfDay(for: referenceDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? referenceDate
            return (start, end)
            
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? referenceDate
            return (start, end)
            
        case .quincena:
            // Quincena boundaries: 1st through 15th, and 16th through end of month
            let day = calendar.component(.day, from: referenceDate)
            var components = calendar.dateComponents([.year, .month], from: referenceDate)
            
            if day <= 15 {
                // First half: 1st to 16th (12:00 AM)
                components.day = 1
                let start = calendar.date(from: components) ?? referenceDate
                components.day = 16
                let end = calendar.date(from: components) ?? referenceDate
                return (start, end)
            } else {
                // Second half: 16th to 1st of next month (12:00 AM)
                components.day = 16
                let start = calendar.date(from: components) ?? referenceDate
                let end = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: {
                    var c = components
                    c.day = 1
                    return c
                }()) ?? referenceDate) ?? referenceDate
                return (start, end)
            }
            
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? referenceDate
            return (start, end)
            
        case .yearly:
            let components = calendar.dateComponents([.year], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: .year, value: 1, to: start) ?? referenceDate
            return (start, end)
            
        case .custom:
            // Reads explicit window properties stored on SpendingLimit
            let start = spendingLimit.startDate ?? referenceDate
            let end = spendingLimit.endDate ?? referenceDate
            return (start, end)
        }
    }
}
