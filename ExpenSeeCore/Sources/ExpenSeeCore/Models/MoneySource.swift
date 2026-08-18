//
//  MoneySource.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import Foundation
import SwiftData

@Model
public final class MoneySource {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var balance: Decimal
    public var hexColor: String?
    public var iconString: String?
    
    @Relationship(deleteRule: .cascade, inverse: \SpendingRecord.source)
    public var spendingRecords: [SpendingRecord]
    
    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .init(),
        balance: Decimal,
        hexColor: String?,
        iconString: String?,
        spendingRecords: [SpendingRecord] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.balance = balance
        self.hexColor = hexColor
        self.iconString = iconString
        self.spendingRecords = spendingRecords
    }
}
