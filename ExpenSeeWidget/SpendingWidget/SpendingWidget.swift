//
//  DailyBudgetWidget.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import WidgetKit
import SwiftUI
import SwiftData
import ExpenSeeCore

struct SpendingWidget: Widget {
    let kind: String = "SpendingWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: SpendingTimelineProvider()
        ) { entry in
            SpendingWidgetView(entry: entry)
        }
        .configurationDisplayName("Spending")
        .description("Keep track of your daily limit and spending in real time.")
        #if os(iOS)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        #endif
    }
}

// MARK: - Previews
#Preview("Small Home Screen", as: .systemSmall) {
    SpendingWidget()
} timeline: {
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 57.50,
        configuration: ConfigurationAppIntent(),
        name: "Daily"
    )
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 115.00,
        configuration: ConfigurationAppIntent(),
        name: "Daily"
    )
}

#Preview("Medium Home Screen", as: .systemMedium) {
    SpendingWidget()
} timeline: {
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 57.50,
        configuration: ConfigurationAppIntent(),
        name: "Daily"
    )
}

#if os(iOS)
#Preview("Circular Lock Screen", as: .accessoryCircular) {
    SpendingWidget()
} timeline: {
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 57.50,
        configuration: ConfigurationAppIntent(),
        name: "Daily"
    )
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 520.50,
        configuration: ConfigurationAppIntent(),
        name: "Daily"
    )
}

#Preview("Rectangular Lock Screen", as: .accessoryRectangular) {
    SpendingWidget()
} timeline: {
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 57.50,
        configuration: ConfigurationAppIntent(),
        name: "Daily"
    )
}
#endif
