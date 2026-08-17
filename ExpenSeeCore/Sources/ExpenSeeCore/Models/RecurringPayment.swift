//
//  RecurringPayment.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

public enum PaymentFrequency: String, Codable {
    case daily, weekly, monthly, yearly
}

@Model
public final class RecurringPayment {
    public var id: UUID
    public var name: String
    public var amount: Decimal
    public var frequencyRawValue: String
    public var nextDueDate: Date
    
    @Relationship public var category: SpendingCategory?
    @Relationship public var source: MoneySource?
    
    public var frequency: PaymentFrequency {
        get { PaymentFrequency(rawValue: frequencyRawValue) ?? .monthly }
        set { frequencyRawValue = newValue.rawValue }
    }
    
    public init(id: UUID = UUID(), name: String, amount: Decimal, frequency: PaymentFrequency, nextDueDate: Date, category: SpendingCategory? = nil, source: MoneySource? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.frequencyRawValue = frequency.rawValue
        self.nextDueDate = nextDueDate
        self.category = category
        self.source = source
    }
}
