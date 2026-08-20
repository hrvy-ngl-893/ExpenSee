//
//   SpendingRepository.swift
//   ExpenSee
//
//   Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
public class SpendingRepository {
    private let context: ModelContext
    private let budgetEngine: BudgetEngine
    
    public init(context: ModelContext, budgetEngine: BudgetEngine = BudgetEngine()) {
        self.context = context
        self.budgetEngine = budgetEngine
    }
    
    /// Creates and persists a new SpendingCategory.
    @discardableResult
    public func createCategory(name: String, hexColor: String = "#007AFF", iconString: String = "cart") throws -> SpendingCategory {
        let category = SpendingCategory(
            name: name,
            hexColor: hexColor,
            iconString: iconString
        )
        context.insert(category)
        try context.save()
        return category
    }
    
    /// Logs a spending expense, deducts the amount from the target account balance, and refreshes UI extensions.
    public func logSpending(
        amount: Decimal,
        category: SpendingCategory?,
        account: Account,
        spendingLimit: SpendingLimit,
        note: String
    ) throws {
        // 1. Initialize new expense transaction
        let transaction = Transaction(
            amount: amount,
            timestamp: Date(),
            note: note,
            type: .expense,
            category: category,
            account: account,
            spendingLimit: spendingLimit
        )
        
        // 2. Insert into SwiftData context
        context.insert(transaction)
        
        // 3. Deduct from account balance to drive live UI updates
        account.balance -= amount
        
        // 4. Commit changes to persistent store
        try context.save()
        
        // 5. Update WidgetKit and Live Activities
        Task {
            await refreshExtensions()
        }
    }

    /// Logs generic transactions (Expense, Income, or Transfer) with correct account balance modifications.
    public func logTransaction(
        amount: Decimal,
        type: TransactionType = .expense,
        note: String = "",
        category: SpendingCategory? = nil,
        account: Account,
        destinationAccount: Account? = nil,
        spendingLimit: SpendingLimit? = nil,
        savingsGoal: SavingsGoal? = nil
    ) throws {
        let transaction = Transaction(
            amount: amount,
            timestamp: Date(),
            note: note,
            type: type,
            category: category,
            account: account,
            destinationAccount: destinationAccount,
            spendingLimit: spendingLimit,
            savingsGoal: savingsGoal
        )
        
        context.insert(transaction)
        
        // Mutate relevant account balances directly based on transaction type
        switch type {
        case .expense:
            account.balance -= amount
        case .income:
            account.balance += amount
        case .transfer:
            account.balance -= amount
            destinationAccount?.balance += amount
        }
        
        try context.save()
        
        Task {
            await refreshExtensions()
        }
    }

    /// Deletes a transaction and reverts affected account balances.
    public func delete(record: Transaction) throws {
        // Revert balance changes based on transaction type
        switch record.type {
        case .expense:
            record.account?.balance += record.amount
        case .income:
            record.account?.balance -= record.amount
        case .transfer:
            record.account?.balance += record.amount
            record.destinationAccount?.balance -= record.amount
        }

        // Remove transaction from SwiftData context
        context.delete(record)
        try context.save()

        Task {
            await refreshExtensions()
        }
    }

    public func getRemainingBudget() throws -> Decimal {
        return try budgetEngine.calculateRemainingToday(context: context)
    }

    private func refreshExtensions() async {
        WidgetCenter.shared.reloadAllTimelines()

        #if os(iOS)
        do {
            let remainingDecimal = try getRemainingBudget()
            let remaining = NSDecimalNumber(decimal: remainingDecimal).doubleValue
            let spentTodayDecimal = try calculateSpentToday()
            let spentToday = NSDecimalNumber(decimal: spentTodayDecimal).doubleValue

            if #available(iOS 16.2, *) {
                let updatedState = SpendingActivityAttributes.ContentState(
                    remainingBudget: remaining,
                    spentToday: spentToday
                )

                for activity in Activity<SpendingActivityAttributes>.activities {
                    let content = ActivityContent(state: updatedState, staleDate: nil)
                    await activity.update(content)
                }
            }
        } catch {
            print("Failed to fetch budget for Live Activity update: \(error.localizedDescription)")
        }
        #endif
    }

    private func calculateSpentToday() throws -> Decimal {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }

        let records = try context.fetch(FetchDescriptor<Transaction>())
        let todaysRecords = records.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay && $0.type == .expense }
        return todaysRecords.reduce(Decimal(0)) { $0 + $1.amount }
    }
}
