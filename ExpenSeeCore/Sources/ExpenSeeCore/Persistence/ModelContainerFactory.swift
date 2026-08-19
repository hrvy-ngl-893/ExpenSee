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
        // 1. Categories and an account
        let sampleCategory = SpendingCategory(name: "Food & Drinks", hexColor: "#0FD76A")
        let entertainmentCategory = SpendingCategory(name: "Entertainment", hexColor: "#FF9500")

        let sampleAccount = Account(
            name: "Credit Card",
            balance: 2000,
            currencyCode: "USD",
            hexColor: "#0FD76A",
            iconString: "fork"
        )
        
        let sampleAccount2 = Account(
            name: "Debit Card",
            balance: 20000,
            currencyCode: "PHP",
            hexColor: "#0FD76A",
            iconString: "fork"
        )

        // 2. Spending limits
        let monthlyFoodLimit = SpendingLimit(
            name: "Monthly Dining",
            limitAmount: 500.00,
            period: .monthly,
            startDate: Date(),
            isActive: true,
            category: sampleCategory
        )

        let entertainmentLimit = SpendingLimit(
            name: "Fun & Movies",
            limitAmount: 150.00,
            period: .monthly,
            startDate: Date(),
            isActive: true,
            category: entertainmentCategory
        )

        // 3. Transactions linked to categories, account, and limits
        let coffeeExpense = Transaction(
            amount: 4.50,
            note: "Coffee",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount,
            spendingLimit: monthlyFoodLimit
        )

        let groceriesExpense = Transaction(
            amount: 65.20,
            note: "Groceries",
            type: .expense,
            category: sampleCategory,
            account: sampleAccount,
            spendingLimit: monthlyFoodLimit
        )

        // 4. Insert everything into the context
        context.insert(sampleCategory)
        context.insert(entertainmentCategory)
        context.insert(sampleAccount)
        context.insert(sampleAccount2)

        context.insert(monthlyFoodLimit)
        context.insert(entertainmentLimit)

        context.insert(coffeeExpense)
        context.insert(groceriesExpense)

        try? context.save()
    }
}
