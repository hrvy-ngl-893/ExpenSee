//
//  SpendingLiveActivityView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//


import SwiftUI
import ActivityKit
import WidgetKit

#if os(iOS) && canImport(ActivityKit)
struct SpendingLiveActivityLockScreenView: View {
    let context: ActivityViewContext<SpendingActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.budgetCycleName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(context.state.remainingBudget, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(context.state.remainingBudget < 0 ? .red : .primary)
                }
                
                Spacer()
                
                Gauge(value: max(0, min(1, context.state.progressValue)), in: 0...1) {
                    Image(systemName: context.state.remainingBudget < 0 ? "exclamationmark.triangle.fill" : "dollarsign.circle")
                } currentValueLabel: {
                    Text(context.state.remainingBudget, format: .number.precision(.fractionLength(0)))
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(context.state.remainingBudget < 0 ? Color.red : Color.green)
            }
            
            HStack {
                Text("Spent Today: \(context.state.spentToday, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Limit: \(context.state.baseDailyLimit, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Previews
#Preview("Lock Screen", as: .content, using: SpendingActivityAttributes(budgetCycleName: "Daily Budget")) {
    SpendingLiveActivity()
} contentStates: {
    SpendingActivityAttributes.ContentState(
        remainingBudget: 42.50,
        spentToday: 57.50,
        baseDailyLimit: 100.00,
        lastExpenseAmount: 12.50,
        lastExpenseCategory: "Coffee"
    )
    SpendingActivityAttributes.ContentState(
        remainingBudget: -15.00,
        spentToday: 115.00,
        baseDailyLimit: 100.00,
        lastExpenseAmount: 45.00,
        lastExpenseCategory: "Dinner"
    )
}
#endif
