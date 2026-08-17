//
//  DailyBudgetRule.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

@Model
public final class DailyBudgetRule {
    public var id: UUID
    public var baseDailyLimit: Decimal
    public var effectiveFrom: Date
    public var isCurrent: Bool
    
    public init(id: UUID = UUID(), baseDailyLimit: Decimal, effectiveFrom: Date = Date(), isCurrent: Bool = true) {
        self.id = id
        self.baseDailyLimit = baseDailyLimit
        self.effectiveFrom = effectiveFrom
        self.isCurrent = isCurrent
    }
}
