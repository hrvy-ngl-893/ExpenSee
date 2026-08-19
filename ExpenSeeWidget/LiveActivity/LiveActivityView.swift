//
//  ExpenSeeLiveActivityView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import ActivityKit
import WidgetKit

#if os(iOS) && canImport(ActivityKit)
struct LiveActivityLockScreenView: View {
    let context: ActivityViewContext<LiveActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // MARK: - Header: Budget Name, Remaining Amount & Status Gauge
            VStack(spacing: 2) {
                ZStack {
                    HStack(alignment: .center) {
                        Text("Remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        
                        Spacer(minLength: 12)
                        
                        Text("Spent")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(alignment: .center) {
                        Text(context.attributes.budgetCycleName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                
                HStack {
                    Text(context.state.remainingBudget, format: .currency(code: context.state.currencyCode))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(context.state.remainingBudget < 0 ? .red : .green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer(minLength: 12)
                    
                    Text(context.state.spentToday, format: .currency(code: context.state.currencyCode))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            
            // MARK: - Progress Bar
            ProgressView(value: max(0, min(1, context.state.progressValue)))
                .tint(context.state.remainingBudget < 0 ? .red : .green)
            
            // MARK: - Footer Metrics: Last Transaction & Budget Limit
            HStack(spacing: 2) {
                if let lastAmount = context.state.lastExpenseAmount,
                   let category = context.state.lastExpenseCategory {
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
                } else {
                    Text("No spending yet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
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
        .padding(16)
    }
}

// MARK: - Previews
#Preview("Lock Screen", as: .content, using: LiveActivityAttributes(budgetCycleName: "Daily Budget")) {
    LiveActivity()
} contentStates: {
    LiveActivityAttributes.ContentState(
        remainingBudget: 42.50,
        spentToday: 57.50,
        baseDailyLimit: 100.00,
        currencyCode: "USD",
        lastExpenseAmount: 12.50,
        lastExpenseCategory: "Coffee"
    )
    LiveActivityAttributes.ContentState(
        remainingBudget: -15.00,
        spentToday: 115.00,
        baseDailyLimit: 100.00,
        currencyCode: "USD",
        lastExpenseAmount: 45.00,
        lastExpenseCategory: "Dinner & Entertainment Extra"
    )
}
#endif
