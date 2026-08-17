//
//  SpendingLiveActivity.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//


import ActivityKit
import WidgetKit
import SwiftUI

#if os(iOS) && canImport(ActivityKit)
struct SpendingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpendingActivityAttributes.self) { context in
            // Lock Screen / Notification Center Banner
            SpendingLiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Region UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent Today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.spentToday, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.remainingBudget, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(context.state.remainingBudget < 0 ? .red : .primary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(value: max(0, min(1, context.state.progressValue)))
                            .tint(context.state.remainingBudget < 0 ? .red : .green)
                        
                        if let lastAmount = context.state.lastExpenseAmount,
                           let category = context.state.lastExpenseCategory {
                            HStack {
                                Text("Last: \(category)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("-\(lastAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(context.state.remainingBudget < 0 ? .red : .green)
            } compactTrailing: {
                Text(context.state.remainingBudget, format: .number.precision(.fractionLength(0)))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(context.state.remainingBudget < 0 ? .red : .primary)
            } minimal: {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(context.state.remainingBudget < 0 ? .red : .green)
            }
            .keylineTint(context.state.remainingBudget < 0 ? Color.red : Color.green)
        }
    }
}
#endif
