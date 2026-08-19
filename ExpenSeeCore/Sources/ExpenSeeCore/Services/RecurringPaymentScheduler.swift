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
            // Ensure payment has a valid Account before logging spending
            guard let source = payment.account else {
                print("⚠️ Skipping recurring payment '\(payment.name)': Missing Account.")
                continue
            }
            
            // 1. Create a Transaction for the payment
            let record = Transaction(
                amount: payment.amount,
                timestamp: payment.nextDueDate,
                note: "Auto-generated: \(payment.name)",
                category: payment.category,
                account: source // <-- Use the unwrapped `source` here
            )
            context.insert(record)
            
            // 2. Advance the next due date
            payment.nextDueDate = calculateNextDueDate(from: payment.nextDueDate, frequency: payment.frequency)
        }
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    private func calculateNextDueDate(from date: Date, frequency: RecurrenceFrequency) -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
            
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
            
        case .quincena:
            // Semi-monthly logic: 1st–15th, and 16th–End of Month
            let day = calendar.component(.day, from: date)
            
            if day <= 15 {
                // Move from current day to the 16th of the same month
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = 16
                return calendar.date(from: components) ?? date
            } else {
                // Move to the 1st of the next month
                guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) else { return date }
                var components = calendar.dateComponents([.year, .month], from: nextMonth)
                components.day = 1
                return calendar.date(from: components) ?? date
            }
            
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
            
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
            
        case .custom:
            // Returning the current date avoids corrupting or wildly shifting the due date.
            return date
        }
    }
}
