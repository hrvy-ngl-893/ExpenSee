//
//  AppIntent.swift
//  ExpenSeeWidget
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import WidgetKit
import AppIntents

import WidgetKit
import AppIntents
import SwiftData
import ExpenSeeCore

// MARK: - AppEntity for SpendingLimit Picker

struct SpendingLimitEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Budget"
    static var defaultQuery = SpendingLimitQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(from budget: SpendingLimit) {
        self.id = budget.id.uuidString
        self.name = budget.name
    }
}

// MARK: - Entity Query Provider

struct SpendingLimitQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [SpendingLimitEntity.ID]) async throws -> [SpendingLimitEntity] {
        let container = ModelContainerFactory.shared
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<SpendingLimit>(
            predicate: #Predicate<SpendingLimit> { $0.isActive }
        )
        let budgets = try context.fetch(descriptor)
        return budgets
            .filter { identifiers.contains($0.id.uuidString) }
            .map { SpendingLimitEntity(from: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [SpendingLimitEntity] {
        let container = ModelContainerFactory.shared
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<SpendingLimit>(
            predicate: #Predicate<SpendingLimit> { $0.isActive }
        )
        let budgets = try context.fetch(descriptor)
        return budgets.map { SpendingLimitEntity(from: $0) }
    }

    @MainActor
    func defaultResult() async -> SpendingLimitEntity? {
        try? await suggestedEntities().first
    }
}

// MARK: - Widget Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Spending Limit"
    static var description: IntentDescription = "Select a budget to track and customize how it appears on your home screen."

    // Parameter 1: Choose WHICH budget (Daily, Weekly, custom, etc.)
    @Parameter(title: "Budget")
    var selectedBudget: SpendingLimitEntity?

    // Parameter 2: Choose HOW to display it (Remaining, Spent, Percentage)
    @Parameter(title: "Display Mode", default: .remaining)
    var displayMode: BudgetDisplayMode

    @Parameter(title: "Show Category Breakdown", default: true)
    var showCategoryBreakdown: Bool
}

// MARK: - Supporting Enums for Customization Options

enum BudgetDisplayMode: String, AppEnum {
    case remaining = "Remaining Balance"
    case spent = "Spent Amount"
    case percentage = "Percentage Spent"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Display Mode"

    static var caseDisplayRepresentations: [BudgetDisplayMode: DisplayRepresentation] = [
        .remaining: DisplayRepresentation(title: "Remaining Balance", subtitle: "Shows remaining balance for selected budget"),
        .spent: DisplayRepresentation(title: "Spent Amount", subtitle: "Shows total spent for selected budget"),
        .percentage: DisplayRepresentation(title: "Percentage Spent", subtitle: "Shows progress bar and % used")
    ]
}
