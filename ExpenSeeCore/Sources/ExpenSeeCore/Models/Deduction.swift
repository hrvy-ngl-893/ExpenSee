//
//  Deduction.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

@Model
public final class Deduction {
    public var id: UUID
    public var name: String
    public var dailyAmount: Decimal
    public var isActive: Bool
    
    public init(id: UUID = UUID(), name: String, dailyAmount: Decimal, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.dailyAmount = dailyAmount
        self.isActive = isActive
    }
}
