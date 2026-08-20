//
//  AccountsViewModel.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//
//  CHANGES FROM ORIGINAL:
//  `addExpense` used to duplicate SpendingRepository.logSpending's balance
//  mutation + transaction creation inline. Two problems with that:
//    1. It never called refreshExtensions(), so an expense logged from
//       wherever this method is used wouldn't update the home screen
//       widget or an in-progress Live Activity — only expenses logged via
//       TransactionView (which uses SpendingRepository directly) did.
//    2. There was no way to pass a spendingLimit, so expenses logged here
//       could never be explicitly earmarked against a limit.
//  Now it delegates to SpendingRepository so there's exactly one code path
//  for "log an expense," and both entry points stay in sync.
//  (addIncome/transfer are untouched — they don't affect spending-limit
//  totals or the widget, so there's no consistency issue there.)
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

    @discardableResult
    public func addIncome(
        to account: Account,
        amountText: String,
        note: String,
        category: SpendingCategory? = nil,
        savingsGoal: SavingsGoal? = nil,
        in context: ModelContext
    ) -> Bool {
        guard
            let amount = parseBalance(amountText),
            amount > 0
        else { return false }

        // 1. Mutate the target account balance
        account.balance += amount

        // 2. Create the income transaction
        let incomeTransaction = Transaction(
            amount: amount,
            timestamp: .now,
            note: note,
            type: .income,
            category: category,
            account: account,
            savingsGoal: savingsGoal,
            currencyCode: account.currencyCode
        )

        context.insert(incomeTransaction)

        do {
            try context.save()
            return true
        } catch {
            print("Failed to save Income transaction: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    public func addExpense(
        from account: Account,
        amountText: String,
        note: String,
        category: SpendingCategory? = nil,
        spendingLimit: SpendingLimit? = nil,
        in context: ModelContext
    ) -> Bool {
        guard
            let amount = parseBalance(amountText),
            amount > 0
        else { return false }

        do {
            try SpendingRepository(context: context).logSpending(
                amount: amount,
                category: category,
                account: account,
                spendingLimit: spendingLimit,
                note: note
            )
            return true
        } catch {
            print("Failed to save Expense transaction: \(error.localizedDescription)")
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
        // Note: any SpendingLimit scoped to this account will pick up the
        // new currencyCode automatically on next read — it's derived live,
        // not snapshotted, so there's nothing else to update here.

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
