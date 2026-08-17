//
//  SpendingRecord.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

@Model
public final class SpendingRecord {
    public var id: UUID
    public var amount: Decimal
    public var timestamp: Date
    public var note: String
    
    @Relationship public var category: SpendingCategory?
    @Relationship public var source: MoneySource?
    
    public init(id: UUID = UUID(), amount: Decimal, timestamp: Date = Date(), note: String = "", category: SpendingCategory? = nil, source: MoneySource? = nil) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
        self.note = note
        self.category = category
        self.source = source
    }
}
