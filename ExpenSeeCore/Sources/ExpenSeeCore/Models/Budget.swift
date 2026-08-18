//
//  Budget.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/17/26.
//


import Foundation
import SwiftData

public enum BudgetPeriod: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case assignable
}

@Model
public final class Budget: Identifiable {
    public var id: UUID
    public var name: String
    public var limitAmount: Decimal
    public var periodRawValue: String
    
    // Assignable budget details
    public var startDate: Date
    public var endDate: Date? // Optional for open-ended or auto-renewing budgets
    public var repeatFrequencyRawValue: String? // Uses PaymentFrequency
    public var isActive: Bool
    
    // Relationships
    @Relationship public var category: SpendingCategory?
    @Relationship(deleteRule: .nullify, inverse: \SpendingRecord.budget) 
    public var expenses: [SpendingRecord]
    
    public var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRawValue) ?? .daily }
        set { periodRawValue = newValue.rawValue }
    }
    
    public var repeatFrequency: PaymentFrequency? {
        get { 
            guard let raw = repeatFrequencyRawValue else { return nil }
            return PaymentFrequency(rawValue: raw)
        }
        set { repeatFrequencyRawValue = newValue?.rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        limitAmount: Decimal,
        period: BudgetPeriod = .daily,
        startDate: Date = Date(),
        endDate: Date? = nil,
        repeatFrequency: PaymentFrequency? = nil,
        isActive: Bool = true,
        category: SpendingCategory? = nil,
        expenses: [SpendingRecord] = []
    ) {
        self.id = id
        self.name = name
        self.limitAmount = limitAmount
        self.periodRawValue = period.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.repeatFrequencyRawValue = repeatFrequency?.rawValue
        self.isActive = isActive
        self.category = category
        self.expenses = expenses
    }
}
