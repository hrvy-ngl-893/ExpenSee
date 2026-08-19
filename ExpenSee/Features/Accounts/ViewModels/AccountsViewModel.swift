//
//  AccountsViewModel.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import Foundation
import SwiftData
import ExpenSeeCore

@MainActor
public final class AccountsViewModel {

    public init() {}

    // MARK: - Transfer Funds

    @discardableResult
    public func transfer(
        from source: Account,
        to destination: Account,
        amountText: String,
        note: String,
        in context: ModelContext
    ) -> Bool {
        guard
            source.id != destination.id,
            let amount = parseBalance(amountText),
            amount > 0,
            source.balance >= amount
        else {
            return false
        }

        // 1. Mutate balances
        source.balance -= amount
        destination.balance += amount

        // 2. Create audit transaction record
        let transferTransaction = Transaction(
            amount: amount,
            timestamp: .now,
            note: note,
            type: .transfer,
            account: source,
            destinationAccount: destination,
            currencyCode: source.currencyCode
        )

        context.insert(transferTransaction)

        do {
            try context.save()
            return true
        } catch {
            print("Failed to save Transfer transaction: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Create

    @discardableResult
    public func addAccount(
        name: String,
        balanceText: String,
        currencyCode: String,
        hexColor: String?,
        iconString: String?,
        in context: ModelContext
    ) -> Bool {
        guard
            let name = validatedName(name),
            let balance = parseBalance(balanceText),
            balance >= 0
        else {
            return false
        }

        let account = Account(
            name: name,
            balance: balance,
            currencyCode: currencyCode,
            hexColor: hexColor,
            iconString: iconString
        )

        context.insert(account)

        do {
            try context.save()
            return true
        } catch {
            context.delete(account)
            print("Failed to save MoneySource: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Update Source

    @discardableResult
    public func updateAccount(
        _ account: Account,
        name: String,
        balanceText: String,
        currencyCode: String,
        hexColor: String?,
        iconString: String?,
        in context: ModelContext
    ) -> Bool {
        guard
            let validatedName = validatedName(name),
            let balance = parseBalance(balanceText),
            balance >= 0
        else {
            return false
        }

        account.name = validatedName
        account.balance = balance
        account.currencyCode = currencyCode
        account.hexColor = hexColor
        account.iconString = iconString

        do {
            try context.save()
            return true
        } catch {
            print("Failed to update MoneySource: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Delete

    @discardableResult
    public func delete(
        _ account: Account,
        from context: ModelContext
    ) -> Bool {
        context.delete(account)

        do {
            try context.save()
            return true
        } catch {
            print("Failed to delete MoneySource: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Validation

    private func validatedName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func parseBalance(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized)
    }
}
