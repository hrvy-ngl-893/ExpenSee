//
//  RecurringPaymentScheduler.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

public struct RecurringPaymentScheduler {
    public init() {}
    
    public func processDuePayments(context: ModelContext) throws {
        let now = Date()
        let descriptor = FetchDescriptor<RecurringPayment>()
        let payments = try context.fetch(descriptor)
        
        let duePayments = payments.filter { $0.nextDueDate <= now }
        
        for payment in duePayments {
            // Ensure payment has a valid MoneySource before logging spending
            guard let source = payment.source else {
                print("⚠️ Skipping recurring payment '\(payment.name)': Missing MoneySource.")
                continue
            }
            
            // 1. Create a SpendingRecord for the payment
            let record = SpendingRecord(
                amount: payment.amount,
                timestamp: payment.nextDueDate,
                note: "Auto-generated: \(payment.name)",
                category: payment.category,
                source: source
            )
            context.insert(record)
            
            // 2. Advance the next due date
            payment.nextDueDate = calculateNextDueDate(from: payment.nextDueDate, frequency: payment.frequency)
        }
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    private func calculateNextDueDate(from date: Date, frequency: PaymentFrequency) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .daily:   return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:  return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:  return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}
