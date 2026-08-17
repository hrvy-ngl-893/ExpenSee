//
//  DailyBudgetWidgetView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import WidgetKit

struct DailyBudgetWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: DailyBudgetTimelineProvider.Entry

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

    // MARK: - Standard Widget Views
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Daily Left")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.remainingBudget, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.system(.title, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Spacer()

            ProgressView(value: progressValue)
                .tint(entry.remainingBudget >= 0 ? .green : .red)

            HStack {
                Text("Limit: \(entry.baseDailyLimit, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            smallWidgetView

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Spent Today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(entry.spentToday, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Daily Base")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(entry.baseDailyLimit, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    // MARK: - Lock Screen Views (iOS Only)
    #if os(iOS)
    @ViewBuilder
    private var accessoryView: some View {
        if family == .accessoryCircular {
            // 1. Determine overbudget status
            let isOverBudget = entry.remainingBudget < 0
            
            // 2. Clamp progress strictly between 0.0 and 1.0 for the filled ring
            let clampedProgress = max(0.0, min(1.0, progressValue))

            Gauge(value: clampedProgress, in: 0...1) {
                Image(systemName: isOverBudget ? "exclamationmark.triangle.fill" : "dollarsign.circle")
            } currentValueLabel: {
                Text(entry.remainingBudget, format: .number.precision(.fractionLength(0)))
            }
            // 3. .accessoryCircularCapacity turns the dot into a filled ring segment
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(isOverBudget ? Color.red : Color.primary)
            .containerBackground(for: .widget) { Color.clear }
        } else {
            VStack(alignment: .leading) {
                Text("Remaining Today")
                    .font(.headline)
                Text(entry.remainingBudget, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .containerBackground(for: .widget) { Color.clear }
        }
    }
    #endif

    private var progressValue: Double {
        let limit = NSDecimalNumber(decimal: entry.baseDailyLimit).doubleValue
        guard limit > 0 else { return 0 }
        let remaining = NSDecimalNumber(decimal: entry.remainingBudget).doubleValue
        return max(0, min(1, remaining / limit))
    }
}
