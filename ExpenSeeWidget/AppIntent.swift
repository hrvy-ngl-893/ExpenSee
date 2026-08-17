//
//  AppIntent.swift
//  ExpenSeeWidget
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import WidgetKit
import AppIntents

// MARK: - Widget Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Daily Budget"
    static var description: IntentDescription = "Choose how your remaining daily budget is displayed on your home screen."

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
        .remaining: DisplayRepresentation(title: "Remaining Balance", subtitle: "Shows remaining budget for today"),
        .spent: DisplayRepresentation(title: "Spent Amount", subtitle: "Shows total spent amount today"),
        .percentage: DisplayRepresentation(title: "Percentage Spent", subtitle: "Shows budget progress bar and % used")
    ]
}
