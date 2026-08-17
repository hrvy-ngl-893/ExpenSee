//
//  DailyBudgetWidget.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import WidgetKit
import SwiftUI

struct DailyBudgetWidget: Widget {
    let kind: String = "DailyBudgetWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: DailyBudgetTimelineProvider()
        ) { entry in
            DailyBudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Budget")
        .description("Keep track of your daily limit and spending in real time.")
        #if os(iOS)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        #endif
    }
}

// MARK: - Previews

#Preview("Small Home Screen", as: .systemSmall) {
    DailyBudgetWidget()
} timeline: {
    DailyBudgetEntry(
        date: .now,
        remainingBudget: 42.50,
        baseDailyLimit: 100.00,
        spentToday: 57.50,
        configuration: ConfigurationAppIntent()
    )
    DailyBudgetEntry(
        date: .now,
        remainingBudget: -15.00,
        baseDailyLimit: 100.00,
        spentToday: 115.00,
        configuration: ConfigurationAppIntent()
    )
}

#Preview("Medium Home Screen", as: .systemMedium) {
    DailyBudgetWidget()
} timeline: {
    DailyBudgetEntry(
        date: .now,
        remainingBudget: 42.50,
        baseDailyLimit: 100.00,
        spentToday: 57.50,
        configuration: ConfigurationAppIntent()
    )
}

#if os(iOS)
#Preview("Circular Lock Screen", as: .accessoryCircular) {
    DailyBudgetWidget()
} timeline: {
    DailyBudgetEntry(
        date: .now,
        remainingBudget: 42.50,
        baseDailyLimit: 100.00,
        spentToday: 57.50,
        configuration: ConfigurationAppIntent()
    )
    DailyBudgetEntry(
        date: .now,
        remainingBudget: -420.50,
        baseDailyLimit: 100.00,
        spentToday: 520.50,
        configuration: ConfigurationAppIntent()
    )
}

#Preview("Rectangular Lock Screen", as: .accessoryRectangular) {
    DailyBudgetWidget()
} timeline: {
    DailyBudgetEntry(
        date: .now,
        remainingBudget: 42.50,
        baseDailyLimit: 100.00,
        spentToday: 57.50,
        configuration: ConfigurationAppIntent()
    )
}
#endif
