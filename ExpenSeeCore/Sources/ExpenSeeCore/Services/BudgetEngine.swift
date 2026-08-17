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
    
    public func calculateRemainingToday(context: ModelContext) throws -> Decimal {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }
        
        // 1. Get current base limit
        var ruleDescriptor = FetchDescriptor<DailyBudgetRule>(predicate: #Predicate { $0.isCurrent })
        ruleDescriptor.fetchLimit = 1
        let currentRule = try context.fetch(ruleDescriptor).first
        let baseLimit = currentRule?.baseDailyLimit ?? 0
        
        // 2. Subtract active deductions
        let deductionDescriptor = FetchDescriptor<Deduction>(predicate: #Predicate { $0.isActive })
        let activeDeductions = try context.fetch(deductionDescriptor)
        let totalDeductions = activeDeductions.reduce(Decimal(0)) { $0 + $1.dailyAmount }
        
        // 3. Subtract today's spent amount
        // Note: SwiftData predicates with dates can be tricky; we filter in memory for safety with Decimals
        let records = try context.fetch(FetchDescriptor<SpendingRecord>())
        let todaysRecords = records.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
        let spentToday = todaysRecords.reduce(Decimal(0)) { $0 + $1.amount }
        
        return baseLimit - totalDeductions - spentToday
    }
}
