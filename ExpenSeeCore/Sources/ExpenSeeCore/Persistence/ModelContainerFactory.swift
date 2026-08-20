//
//  ModelContainerFactory.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

@MainActor
public enum ModelContainerFactory {

    private static let schema = Schema([
        SpendingCategory.self,
        Account.self,
        Transaction.self,
        SpendingLimit.self,
        RecurringPayment.self,
        SavingsGoal.self
    ])

    public static let shared: ModelContainer = {
        let appGroupID = "group.com.harvy-angelo-tan.ExpenSee"

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupID)
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("❌ SwiftData Load Error: \(error.localizedDescription)")

            #if DEBUG
            do {
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Failed to create fallback in-memory container: \(error)")
            }
            #else
            fatalError("Failed to create ModelContainer: \(error)")
            #endif
        }
    }()

    // MARK: - Preview Container with Mock Data
    public static let inMemoryPreview: ModelContainer = {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            seedMockData(into: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error.localizedDescription)")
        }
    }()

    private static func seedMockData(into context: ModelContext) {
        // 1. Categories and accounts.
        // Two accounts in two different currencies on purpose — this is
        // what exercises the currency-scoping logic in previews. If this
        // ever regresses (a PHP transaction bleeding into a USD limit's
        // total), it should be visible just by opening the Dashboard
        // preview.
        let sampleCategory = SpendingCategory(name: "Food & Drinks", hexColor: "#0FD76A")
        let entertainmentCategory = SpendingCategory(name: "Entertainment", hexColor: "#FF9500")

        let sampleAccount = Account(
            name: "Credit Card",
            balance: 2000,
            currencyCode: "USD",
            hexColor: "#0FD76A",
            iconString: "creditcard.fill"
        )

        let sampleAccount2 = Account(
            name: "Debit Card",
            balance: 2002232300,
            currencyCode: "PHP",
            hexColor: "#0FD76A",
            iconString: "creditcard.fill"
        )

        // 2. Spending limits — demonstrating both supported patterns:
        //
        //   - monthlyFoodLimit: account-scoped (Credit Card / USD). Only
        //     transactions on that specific account count, regardless of
        //     what other accounts share the same category.
        //   - entertainmentLimit: currency-wide (USD, no account). Counts
        //     any USD transaction in the Entertainment category, from any
        //     USD account.
        //   - phpDiningLimit: account-scoped (Debit Card / PHP), same
        //     category as monthlyFoodLimit. Proves two limits can share a
        //     category without their totals mixing, since they differ by
        //     account/currency.
        let monthlyFoodLimit = SpendingLimit(
            name: "Monthly Dining (Credit Card)",
            limitAmount: 500.00,
            currencyCode: sampleAccount.currencyCode,
            period: .monthly,
            startDate: Date(),
            isActive: true,
            account: sampleAccount,
            categories: [sampleCategory]
        )

        let entertainmentLimit = SpendingLimit(
            name: "Fun & Movies",
            limitAmount: 150.00,
            currencyCode: "USD",
            period: .monthly,
            startDate: Date(),
            isActive: true,
            categories: [entertainmentCategory]
        )

        let phpDiningLimit = SpendingLimit(
            name: "Monthly Dining (Debit Card)",
            limitAmount: 8000.00,
            currencyCode: sampleAccount2.currencyCode,
            period: .monthly,
            startDate: Date(),
            isActive: true,
            account: sampleAccount2,
            categories: [sampleCategory]
        )

        // 3. Transactions. currencyCode is picked up automatically from
        // each transaction's account in Transaction.init, so it isn't
        // passed explicitly here.
        let coffeeExpense = Transaction(
            amount: 4.50,
            timestamp: .daysAgo(0, hour: 8, minute: 30),
            note: "Morning Coffee",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount,
            spendingLimit: monthlyFoodLimit
        )

        let groceriesExpense = Transaction(
            amount: 65.20,
            timestamp: .daysAgo(1, hour: 17, minute: 45),
            note: "Groceries Run",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount,
            spendingLimit: monthlyFoodLimit
        )

        let streamingSubscription = Transaction(
            amount: 14.99,
            timestamp: .daysAgo(3, hour: 9, minute: 0),
            note: "Streaming Service",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount
        )

        let gasExpense = Transaction(
            amount: 42.50,
            timestamp: .daysAgo(5, hour: 14, minute: 15),
            note: "Gas Station",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount
        )

        // 2. USD Income & Transfers
        let salaryIncome = Transaction(
            amount: 2500.00,
            timestamp: .daysAgo(7, hour: 9, minute: 0),
            note: "Bi-weekly Salary",
            type: .income,
            account: sampleAccount,
        )

        let savingsTransfer = Transaction(
            amount: 500.00,
            timestamp: .daysAgo(6, hour: 10, minute: 30),
            note: "Transfer to Savings",
            type: .transfer,
            account: sampleAccount,
            destinationAccount: sampleAccount2
        )

        // 3. PHP Expenses
        let phpCoffeeExpense = Transaction(
            amount: 180.00,
            timestamp: .daysAgo(0, hour: 13, minute: 10),
            note: "Café Latte",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount2,
            spendingLimit: phpDiningLimit
        )

        let phpGroceriesExpense = Transaction(
            amount: 1450.75,
            timestamp: .daysAgo(2, hour: 18, minute: 20),
            note: "Supermarket Items",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount2,
            spendingLimit: phpDiningLimit
        )

        let phpUtilitiesExpense = Transaction(
            amount: 3200.00,
            timestamp: .daysAgo(4, hour: 11, minute: 0),
            note: "Electric Bill",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount2
        )

        let phpDinnerExpense = Transaction(
            amount: 850.00,
            timestamp: .daysAgo(8, hour: 20, minute: 0),
            note: "Weekend Dinner",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount2,
            spendingLimit: phpDiningLimit
        )

        let sampleTransactions: [Transaction] = [
            coffeeExpense,
            groceriesExpense,
            streamingSubscription,
            gasExpense,
            salaryIncome,
            savingsTransfer,
            phpCoffeeExpense,
            phpGroceriesExpense,
            phpUtilitiesExpense,
            phpDinnerExpense
        ]
        // 4. Insert everything into the context
        context.insert(sampleCategory)
        context.insert(entertainmentCategory)
        context.insert(sampleAccount)
        context.insert(sampleAccount2)

        context.insert(monthlyFoodLimit)
        context.insert(entertainmentLimit)
        context.insert(phpDiningLimit)

        for transaction in sampleTransactions {
            context.insert(transaction)
        }

        try? context.save()
    }
}
