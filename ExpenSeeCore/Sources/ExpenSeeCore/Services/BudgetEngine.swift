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
        let budgetDescriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { $0.isActive && $0.periodRawValue == "daily" }
        )
        let dailyBudgets = try context.fetch(budgetDescriptor)
        let baseLimit = dailyBudgets.first?.limitAmount ?? 0
        
        // 2. Subtract active deductions
        let deductionDescriptor = FetchDescriptor<Deduction>(predicate: #Predicate { $0.isActive })
        let activeDeductions = try context.fetch(deductionDescriptor)
        let totalDeductions = activeDeductions.reduce(Decimal(0)) { $0 + $1.dailyAmount }
        
        // 3. Subtract today's total spending records
        let records = try context.fetch(FetchDescriptor<SpendingRecord>())
        let todaysRecords = records.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
        let spentToday = todaysRecords.reduce(Decimal(0)) { $0 + $1.amount }
        
        return baseLimit - totalDeductions - spentToday
    }
    
    // MARK: - General Budget Status Calculation
    
    /// Calculates remaining amount for any specific Budget instance (Daily, Weekly, Monthly, or Assignable).
    public func calculateRemaining(for budget: Budget, context: ModelContext) throws -> Decimal {
        guard budget.isActive else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        
        let (startDate, endDate) = resolveDateInterval(for: budget, referenceDate: now, calendar: calendar)
        
        // Fetch all relevant expenses matching date range, optional category, or explicit budget attachment
        let records = try context.fetch(FetchDescriptor<SpendingRecord>())
        let relevantRecords = records.filter { record in
            guard record.timestamp >= startDate && record.timestamp <= endDate else { return false }
            
            // If explicitly attached to this budget, count it
            if let assignedBudget = record.budget, assignedBudget.id == budget.id {
                return true
            }
            
            // If budget is assigned to a specific category, match by category
            if let targetCategory = budget.category {
                return record.category?.id == targetCategory.id
            }
            
            // Otherwise, apply to unassigned global period budgets
            return record.budget == nil
        }
        
        let totalSpent = relevantRecords.reduce(Decimal(0)) { $0 + $1.amount }
        return budget.limitAmount - totalSpent
    }
    
    // MARK: - Helper Methods
    
    private func resolveDateInterval(for budget: Budget, referenceDate: Date, calendar: Calendar) -> (Date, Date) {
        switch budget.period {
        case .daily:
            let start = calendar.startOfDay(for: referenceDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? referenceDate
            return (start, end)
            
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? referenceDate
            return (start, end)
            
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? referenceDate
            return (start, end)
            
        case .assignable:
            let start = budget.startDate
            let end = budget.endDate ?? Date.distantFuture
            return (start, end)
        }
    }
}
