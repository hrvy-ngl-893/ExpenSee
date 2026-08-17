//
//  DeductionCalculator.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

public struct DeductionCalculator {
    public init() {}
    
    public func totalActiveDailyDeductions(context: ModelContext) throws -> Decimal {
        let descriptor = FetchDescriptor<Deduction>(predicate: #Predicate { $0.isActive })
        let deductions = try context.fetch(descriptor)
        return deductions.reduce(Decimal(0)) { $0 + $1.dailyAmount }
    }
}
