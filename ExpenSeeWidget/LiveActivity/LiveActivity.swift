//
//  LiveActivity.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

#if os(iOS) && canImport(ActivityKit)
struct LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            LiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Region UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(context.state.remainingBudget, format: .currency(code: context.state.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(context.state.remainingBudget < 0 ? .red : .green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Spent")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(context.state.spentToday, format: .currency(code: context.state.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(.trailing, 8)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.budgetCycleName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressView(value: max(0, min(1, context.state.progressValue)))
                            .tint(context.state.remainingBudget < 0 ? .red : .green)
                        
                        if let lastAmount = context.state.lastExpenseAmount,
                           let category = context.state.lastExpenseCategory {
                            HStack(spacing: 2) {
                                HStack(spacing: 2) {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text("\(category): ")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                
                                Text("-\(lastAmount, format: .currency(code: context.state.currencyCode))")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Spacer(minLength: 8)
                                
                                Text("Limit: ")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Text(context.state.baseDailyLimit, format: .currency(code: context.state.currencyCode))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                }
            } compactLeading: {
                BudgetGaugeView(
                        remainingBudget: context.state.remainingBudget,
                        baseDailyLimit: context.state.baseDailyLimit
                    )
                .padding(.trailing, 2)
                
            } compactTrailing: {
                Text(
                    context.state.remainingBudget,
                    format: .currency(code: context.state.currencyCode).precision(.fractionLength(0))
                )
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(context.state.remainingBudget < 0 ? .red : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            } minimal: {
                BudgetGaugeView(
                        remainingBudget: context.state.remainingBudget,
                        baseDailyLimit: context.state.baseDailyLimit
                    )
            }
            .keylineTint(context.state.remainingBudget < 0 ? Color.red : Color.green)
        }
    }
}

// MARK: - Previews
#Preview("Live Activity", as: .dynamicIsland(.expanded), using: LiveActivityAttributes(budgetCycleName: "Daily Budget")) {
    LiveActivity()
} contentStates: {
    LiveActivityAttributes.ContentState(
        remainingBudget: 500.00,
        spentToday: 0.00,
        baseDailyLimit: 500.00,
        currencyCode: "PHP",
        lastExpenseAmount: 0.00,
        lastExpenseCategory: "None"
    )
    
    LiveActivityAttributes.ContentState(
        remainingBudget: 350.00,
        spentToday: 150.00,
        baseDailyLimit: 500.00,
        currencyCode: "PHP",
        lastExpenseAmount: 45.00,
        lastExpenseCategory: "Groceries"
    )
    
    LiveActivityAttributes.ContentState(
        remainingBudget: -25.50,
        spentToday: 525.50,
        baseDailyLimit: 500.00,
        currencyCode: "PHP",
        lastExpenseAmount: 12.50,
        lastExpenseCategory: "Coffee"
    )
}

struct BudgetGaugeView: View {
    let remainingBudget: Decimal
    let baseDailyLimit: Decimal
    
    var body: some View {
        let totalBudget = NSDecimalNumber(decimal: baseDailyLimit).doubleValue
        let remaining = NSDecimalNumber(decimal: remainingBudget).doubleValue
        let isNegative = remainingBudget < 0
        
        // Clamp value between 0 and totalBudget for the gauge fill
        let currentProgress = totalBudget > 0 ? max(0.0, min(totalBudget, remaining)) : 0.0

        Gauge(value: currentProgress, in: 0...max(0.001, totalBudget)) {
            // Label (optional)
            Text("Budget")
        } currentValueLabel: {
            // Center Content
            Image(systemName: isNegative ? "exclamationmark" : "dollarsign")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(isNegative ? .red : .green)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(isNegative ? Color.red : Color.green)
        .scaleEffect(0.45)
        .frame(width: 20, height: 20)
        .padding(.horizontal, 2)
    }
}

#Preview("Live Activity", as: .dynamicIsland(.minimal), using: LiveActivityAttributes(budgetCycleName: "Daily Budget")) {
    LiveActivity()
} contentStates: {
    LiveActivityAttributes.ContentState(
        remainingBudget: 500.00,
        spentToday: 0.00,
        baseDailyLimit: 500.00,
        currencyCode: "PHP",
        lastExpenseAmount: 0.00,
        lastExpenseCategory: "None"
    )
    
    LiveActivityAttributes.ContentState(
        remainingBudget: 350.00,
        spentToday: 150.00,
        baseDailyLimit: 500.00,
        currencyCode: "PHP",
        lastExpenseAmount: 45.00,
        lastExpenseCategory: "Groceries"
    )
    
    LiveActivityAttributes.ContentState(
        remainingBudget: -25.50,
        spentToday: 525.50,
        baseDailyLimit: 500.00,
        currencyCode: "PHP",
        lastExpenseAmount: 12.50,
        lastExpenseCategory: "Coffee"
    )
}
#endif
