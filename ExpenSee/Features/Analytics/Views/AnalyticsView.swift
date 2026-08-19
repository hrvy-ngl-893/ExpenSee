//
//  AnalyticsView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

public struct AnalyticsView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = AnalyticsViewModel()
    
    public init() {}
    
    public var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Timeframe", selection: $viewModel.timeframe) {
                        ForEach(AnalyticsTimeframe.allCases) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.timeframe) {
                        viewModel.loadData(context: context)
                    }
                    
                    // Summary Metric Cards
                    HStack(spacing: 15) {
                        MetricCard(title: "Total Spent", amount: viewModel.totalSpent, icon: "creditcard.fill", color: .red)
                        MetricCard(title: "Daily Average", amount: viewModel.averageDailySpend, icon: "chart.line.uptrend.xyaxis", color: .blue)
                    }
                    .padding(.horizontal)
                    
                    // Spending Trend Chart Component
                    VStack {
                        SpendingTrendChartView(trends: viewModel.dailyTrend)
                    }
                    .padding()
                    .background(.background)
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .padding(.horizontal)
                    
                    // Category Breakdown Chart Component
                    VStack {
                        CategoryBreakdownChartView(summaries: viewModel.categorySummaries)
                    }
                    .padding()
                    .background(.background)
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .padding(.horizontal)
                    
                    // Source Breakdown List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Breakdown by Funding Source")
                            .font(.headline)
                        
                        if viewModel.sourceSpending.isEmpty {
                            Text("No funding source data available.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.sourceSpending.sorted(by: { $0.value > $1.value }), id: \.key) { source, amount in
                                HStack {
                                    Text(source)
                                    Spacer()
                                    Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                        .bold()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    .background(.background)
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .padding(.horizontal)
                    
                    // Biggest Expenses List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Biggest Expenses")
                            .font(.headline)
                        
                        if viewModel.biggestTransactionsList.isEmpty {
                            Text("No major expenses recorded.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.biggestTransactionsList) { record in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(record.note.isEmpty ? "Expense" : record.note)
                                            .font(.subheadline)
                                            .bold()
                                        Text(record.timestamp, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(record.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                        .foregroundColor(.red)
                                        .bold()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    .background(.background)
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .onAppear {
                viewModel.loadData(context: context)
            }
        }
    }
}

private struct MetricCard: View {
    let title: String
    let amount: Decimal
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}
