//
//  SpendingWidgetView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import WidgetKit

struct SpendingWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: SpendingTimelineProvider.Entry

    var body: some View {
        switch family {
        #if os(iOS)
        case .accessoryCircular, .accessoryInline, .accessoryRectangular:
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
        case .remaining: return "Remaining"
        case .spent: return "Spent"
        case .percentage: return "Used"
        }
    }

    private var primaryDisplayValue: String {
        let remaining = entry.spendingLimit - entry.spent
        switch entry.configuration.displayMode {
        case .remaining:
            return remaining.formatted(.currency(code: entry.currencyCode))
        case .spent:
            return entry.spent.formatted(.currency(code: entry.currencyCode))
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
        let remaining = entry.spendingLimit - entry.spent
        let progress = entry.spendingLimit > 0
            ? Double(truncating: (entry.spent / entry.spendingLimit) as NSNumber)
            : 0.0
        let isOverBudget = remaining < 0
        let statusColor: Color = isOverBudget ? .red : .green

        return VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header (Icon & Name)
            HStack(spacing: 4) {
                if let displayIcon = entry.iconString, !displayIcon.isEmpty {
                    Image(systemName: displayIcon)
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                }
                Text(entry.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // MARK: - Hero Metric (Based on displayMode configuration)
            VStack(alignment: .leading, spacing: 1) {
                Text(isOverBudget && entry.configuration.displayMode == .remaining ? "Over Budget" : headerTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(primaryDisplayValue)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            Spacer()

            // MARK: - Progress & Limit Context
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: max(0, min(1, 1.0 - progress)))
                    .tint(statusColor)

                HStack {
                    Text("Limit")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(entry.spendingLimit, format: .currency(code: entry.currencyCode))
                        .fontWeight(.medium)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var mediumWidgetView: some View {
        let remaining = entry.spendingLimit - entry.spent
        let progress = entry.spendingLimit > 0
            ? Double(truncating: (entry.spent / entry.spendingLimit) as NSNumber)
            : 0.0
        let isOverBudget = remaining < 0
        let statusColor: Color = isOverBudget ? .red : .green

        return VStack {
            HStack {
                HStack(spacing: 6) {
                    if let displayIcon = entry.iconString, !displayIcon.isEmpty {
                        Image(systemName: displayIcon)
                            .font(.caption)
                            .foregroundStyle(statusColor)
                    }
                    Text(entry.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("ExpenSee")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // MARK: - Hero Values (Remaining vs Spent)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(remaining, format: .currency(code: entry.currencyCode))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(statusColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Spent")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.spent, format: .currency(code: entry.currencyCode))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            // MARK: - Progress Gauge
            ProgressView(value: max(0, min(1, 1.0 - progress)))
                .tint(statusColor)

            // MARK: - Footer Details (Conditional Category Breakdown)
            if entry.configuration.showCategoryBreakdown {
                HStack {
                    HStack(spacing: 4) {
                        Text("\(Int(progress * 100))% used")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 2) {
                        Text("Limit: ")
                            .foregroundStyle(.secondary)
                        Text(entry.spendingLimit, format: .currency(code: entry.currencyCode))
                            .fontWeight(.bold)
                    }
                    .font(.caption2)
                }
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
        } else if family == .accessoryInline {
            let remaining = entry.spendingLimit - entry.spent
            let isOverBudget = remaining < 0
            let icon = entry.iconString

            Label {
                Text("\(entry.currencyCode) \(remaining, format: .number.precision(.fractionLength(0)))")
            } icon: {
                Image(systemName: (isOverBudget ? "exclamationmark.triangle.fill" : icon) ?? "dollarsign.circle.fill")
            }
        } else {
            let remaining = entry.spendingLimit - entry.spent
            VStack(alignment: .leading) {
                Text(entry.name)
                    .font(.caption)
                Text(remaining, format: .currency(code: entry.currencyCode))
                    .font(.headline)
                    .fontWeight(.bold)
                ProgressView(value: progressValue)
                    .tint(remaining >= 0 ? .green : .red)
                HStack {
                    Spacer()
                    Text("From \(entry.spendingLimit, format: .currency(code: entry.currencyCode))")
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
        let remaining = NSDecimalNumber(decimal: entry.spendingLimit - entry.spent).doubleValue
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
        currencyCode: "USD",
        iconString: "creditcard.fill",
        name: "Daily"
    )
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 115.00,
        configuration: ConfigurationAppIntent(),
        currencyCode: "USD",
        iconString: "creditcard.fill",
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
        currencyCode: "USD",
        iconString: "creditcard.fill",
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
        currencyCode: "USD",
        iconString: "creditcard.fill",
        name: "Daily"
    )
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 520.50,
        configuration: ConfigurationAppIntent(),
        currencyCode: "USD",
        iconString: "creditcard.fill",
        name: "Daily"
    )
}

#Preview("Inline Lock Screen", as: .accessoryInline) {
    SpendingWidget()
} timeline: {
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 57.50,
        configuration: ConfigurationAppIntent(),
        currencyCode: "USD",
        iconString: "creditcard.fill",
        name: "Daily"
    )
    SpendingEntry(
        date: .now,
        spendingLimit: 100.00,
        spent: 520.50,
        configuration: ConfigurationAppIntent(),
        currencyCode: "USD",
        iconString: "creditcard.fill",
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
        currencyCode: "USD",
        iconString: "creditcard.fill",
        name: "Daily"
    )
}
#endif
