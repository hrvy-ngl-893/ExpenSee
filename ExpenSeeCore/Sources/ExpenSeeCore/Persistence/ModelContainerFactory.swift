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
        MoneySource.self,
        SpendingRecord.self,
        Budget.self,
        Deduction.self,
        RecurringPayment.self
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
        // 1. Create Categories and Sources
        let sampleCategory = SpendingCategory(name: "Food & Drinks", hexColor: "#0FD76A")
        let entertainmentCategory = SpendingCategory(name: "Entertainment", hexColor: "#FF9500")
        
        let sampleSource = MoneySource(name: "Credit Card", balance: 2000, hexColor: "#0FD76A", iconString: "fork")
        
        // 2. Create Budgets
        let monthlyFoodBudget = Budget(
            name: "Monthly Dining",
            limitAmount: 500.00,
            period: .monthly,
            startDate: Date(),
            isActive: true,
            category: sampleCategory
        )
        
        let entertainmentBudget = Budget(
            name: "Fun & Movies",
            limitAmount: 150.00,
            period: .monthly,
            startDate: Date(),
            isActive: true,
            category: entertainmentCategory
        )

        // 3. Create Expenses and link them to categories, sources, and budgets
        let sampleExpense1 = SpendingRecord(
            amount: 4.50,
            note: "Coffee",
            category: sampleCategory,
            source: sampleSource
        )
        sampleExpense1.budget = monthlyFoodBudget

        let sampleExpense2 = SpendingRecord(
            amount: 65.20,
            note: "Groceries",
            category: sampleCategory,
            source: sampleSource
        )
        sampleExpense2.budget = monthlyFoodBudget

        // 4. Insert everything into the context
        context.insert(sampleCategory)
        context.insert(entertainmentCategory)
        context.insert(sampleSource)
        
        context.insert(monthlyFoodBudget)
        context.insert(entertainmentBudget)
        
        context.insert(sampleExpense1)
        context.insert(sampleExpense2)
        
        try? context.save()
    }
}
