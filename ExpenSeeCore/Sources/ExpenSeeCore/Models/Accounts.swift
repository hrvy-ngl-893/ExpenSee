//
//  Accounts.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import Foundation
import SwiftUI
import SwiftData

@Model
public final class Account: Identifiable {
    public var id: UUID
    public var name: String = ""
    public var createdAt: Date = Date.now
    public var balance: Decimal = 0
    public var hexColor: String?
    public var iconString: String?

    /// ISO 4217 currency code (e.g. "USD", "PHP"). Each account carries its
    /// own currency; conversion, if needed, happens at display/report time —
    /// stored amounts are never rewritten into another currency.
    public var currencyCode: String = "USD"

    /// Transactions where this account is the primary account (an expense,
    /// an income entry, or the outgoing side of a transfer).
    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    public var transactions: [Transaction] = []

    /// Incoming legs of transfers where this account is the destination.
    @Relationship(deleteRule: .nullify, inverse: \Transaction.destinationAccount)
    public var incomingTransfers: [Transaction] = []

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        balance: Decimal,
        currencyCode: String = "USD",
        hexColor: String? = nil,
        iconString: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.balance = balance
        self.currencyCode = currencyCode
        self.hexColor = hexColor
        self.iconString = iconString
    }
}

extension Account {
    public var displayIcon: String {
        iconString?.isEmpty == false ? iconString! : "creditcard.circle.fill"
    }

    public var displayColor: Color {
        guard let hexColor, !hexColor.isEmpty else { return .blue }
        return Color(hex: hexColor) ?? .blue
    }
}
