//
//  CategoryBreakdownChartView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import Charts
import ExpenSeeCore

public struct CategoryBreakdownChartView: View {
    public let summaries: [AnalyticsViewModel.CategorySummary]
    
    public init(summaries: [AnalyticsViewModel.CategorySummary]) {
        self.summaries = summaries
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Distribution")
                .font(.headline)
            
            if summaries.isEmpty {
                ContentUnavailableView("No Spending Data", systemImage: "chart.pie")
            } else {
                Chart(summaries) { item in
                    SectorMark(
                        angle: .value("Amount", item.totalAmount),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(by: .value("Category", item.category.name))
                }
                .frame(height: 200)
                
                ForEach(summaries) { item in
                    HStack {
                        Text(item.category.name)
                        Spacer()
                        Text(item.totalAmount, format: .currency(code: "USD"))
                            .bold()
                        Text(String(format: "(%.1f%%)", item.percentage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
