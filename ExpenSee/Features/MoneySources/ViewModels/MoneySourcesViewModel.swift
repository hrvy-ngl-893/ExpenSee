//
//  MoneySourcesViewModel.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import Foundation
import SwiftData
import ExpenSeeCore

@MainActor
public final class MoneySourcesViewModel {

    public init() {}

    // MARK: - Create

    @discardableResult
    public func addSource(
        name: String,
        balanceText: String,
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

        let source = MoneySource(
            name: name,
            balance: balance,
            hexColor: hexColor,
            iconString: iconString
        )

        context.insert(source)

        do {
            try context.save()
            return true
        } catch {
            context.delete(source)
            print("Failed to save MoneySource: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Update Source

    @discardableResult
    public func updateSource(
        _ source: MoneySource,
        name: String,
        balanceText: String,
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

        source.name = validatedName
        source.balance = balance
        source.hexColor = hexColor
        source.iconString = iconString

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
        _ source: MoneySource,
        from context: ModelContext
    ) -> Bool {
        context.delete(source)

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
