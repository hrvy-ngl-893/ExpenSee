//
//  RecurringPaymentCalculator.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

public struct RecurringPaymentCalculator {
    public init() {}
    
    public func totalActiveRecurringPayment(context: ModelContext) throws -> Decimal {
        let descriptor = FetchDescriptor<RecurringPayment>(predicate: #Predicate { $0.isActive })
        let recurring = try context.fetch(descriptor)
        return recurring.reduce(into: Decimal(0)) { $0 + $1.amount }
    }
}
