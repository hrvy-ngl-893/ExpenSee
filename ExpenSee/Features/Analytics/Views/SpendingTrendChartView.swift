//
//  SpendingTrendChartView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import Charts
import ExpenSeeCore

public struct SpendingTrendChartView: View {
    public let trends: [AnalyticsViewModel.TrendPoint]
    
    public init(trends: [AnalyticsViewModel.TrendPoint]) {
        self.trends = trends
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Over Time")
                .font(.headline)
            
            if trends.isEmpty {
                ContentUnavailableView("No Trend Data", systemImage: "chart.line.uptrend.xyaxis")
                    .frame(height: 180)
            } else {
                Chart(trends) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Amount", item.totalAmount)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 180)
            }
        }
    }
}
