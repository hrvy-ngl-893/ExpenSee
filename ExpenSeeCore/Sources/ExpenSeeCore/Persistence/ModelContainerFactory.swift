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

    public static let shared: ModelContainer = {
        let schema = Schema([
            SpendingCategory.self,
            MoneySource.self,
            SpendingRecord.self,
            DailyBudgetRule.self,
            Deduction.self,
            RecurringPayment.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
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
}
