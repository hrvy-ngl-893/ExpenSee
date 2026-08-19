//
//  SpendingWidgetView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import WidgetKit

struct SpendingWidgetView: View {
    @AppStorage("userCurrencyCode", store: UserDefaults(suiteName: "group.com.harvy-angelo-tan.ExpenSee"))
    private var currencyCode: String = "USD"
    
    @Environment(\.widgetFamily) var family
    var entry: SpendingTimelineProvider.Entry

    var body: some View {
        switch family {
        #if os(iOS)
        case .accessoryCircular, .accessoryRectangular:
            accessoryView
        #endif
        case .systemSmall:
            smallWidgetView
        default:
            mediumWidgetView
        }
    }

    // MARK: - Display Helpers Based on Configuration
    private var headerTitle: String {
        switch entry.configuration.displayMode {
        case .remaining: return "Left"
        case .spent: return "Spent"
        case .percentage: return "Used"
        }
    }

    private var primaryDisplayValue: String {
        let remaining = entry.spendingLimit - entry.spent
        switch entry.configuration.displayMode {
        case .remaining:
            return remaining.formatted(.currency(code: currencyCode))
        case .spent:
            return entry.spent.formatted(.currency(code: currencyCode))
        case .percentage:
            let limit = NSDecimalNumber(decimal: entry.spendingLimit).doubleValue
            guard limit > 0 else { return "0%" }
            let spent = NSDecimalNumber(decimal: entry.spent).doubleValue
            let pct = (spent / limit) * 100
            return String(format: "%.0f%%", pct)
        }
    }

    // MARK: - Standard Widget Views
    private var smallWidgetView: some View {

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(headerTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(primaryDisplayValue)
                .font(.system(.title, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Spacer()

            ProgressView(value: progressValue)
                .tint((entry.spendingLimit - entry.spent) >= 0 ? .green : .red)

            HStack {
                Text("Limit: \(entry.spendingLimit, format: .currency(code: currencyCode))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            smallWidgetView

            if entry.configuration.showCategoryBreakdown {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Spent Today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.spent, format: .currency(code: currencyCode))
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Daily Base")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.spendingLimit, format: .currency(code: currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    // MARK: - Lock Screen Views (iOS Only)
    #if os(iOS)
    @ViewBuilder
    private var accessoryView: some View {
        if family == .accessoryCircular {
            let remaining = entry.spendingLimit - entry.spent
            let isOverBudget = remaining < 0
            let clampedProgress = max(0.0, min(1.0, progressValue))

            Gauge(value: clampedProgress, in: 0...1) {
                Image(systemName: isOverBudget ? "exclamationmark.triangle.fill" : "dollarsign.circle")
            } currentValueLabel: {
                Text(remaining, format: .number.precision(.fractionLength(0)))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(isOverBudget ? Color.red : Color.primary)
            .containerBackground(for: .widget) { Color.clear }
        } else {
            let remaining = entry.spendingLimit - entry.spent
            VStack(alignment: .leading) {
                Text(entry.name)
                    .font(.caption)
                Text(remaining, format: .currency(code: currencyCode))
                    .font(.headline)
                    .fontWeight(.bold)
                ProgressView(value: progressValue)
                    .tint(remaining >= 0 ? .green : .red)
                HStack() {
                    Spacer()
                    Text("From \(entry.spendingLimit, format: .currency(code: currencyCode))")
                        .font(.footnote)
                }
            }
            .containerBackground(for: .widget) { Color.clear }
        }
    }
    #endif

    private var progressValue: Double {
        let limit = NSDecimalNumber(decimal: entry.spendingLimit).doubleValue
        guard limit > 0 else { return 0 }
        let remaining = NSDecimalNumber(decimal:  entry.spendingLimit - entry.spent).doubleValue
        return max(0, min(1, remaining / limit))
    }
}

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
