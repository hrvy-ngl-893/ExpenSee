//
//  AccountHistoryChartView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/19/26.
//

import SwiftUI
import Charts
import SwiftData
import ExpenSeeCore

public enum TimeIntervalStep: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    public var id: String { rawValue }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        }
    }
}

public struct HistoricalDataPoint: Identifiable {
    public var id: String { "\(account.id.uuidString)_\(date.timeIntervalSince1970)" }
    public let date: Date
    public let balance: Decimal
    public let account: Account
}

public struct AccountHistoryChartView: View {
    @EnvironmentObject private var settings: SettingsViewModel

    @Query(sort: \Account.name) private var allAccounts: [Account]
    @Query(sort: \ExpenSeeCore.Transaction.timestamp) private var allTransactions: [ExpenSeeCore.Transaction]

    // Chart Configuration State
    @State private var step: TimeIntervalStep = .day
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
    @State private var endDate: Date = .now
    @State private var selectedAccountIDs: Set<UUID> = []
    @State private var rawSelectedDate: Date?

    @State private var showAccountFilterSheet: Bool = false
    @State private var showDatePickerSheet: Bool = false

    public init() {}

    private var activeAccounts: [Account] {
        if selectedAccountIDs.isEmpty {
            return allAccounts
        }
        return allAccounts.filter { selectedAccountIDs.contains($0.id) }
    }

    /// Generates date intervals based on the start date, end date, and chosen step.
    private var dateSteps: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        while current <= end {
            dates.append(current)
            guard let next = calendar.date(byAdding: step.calendarComponent, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    /// Calculates historical point-in-time balances for chosen accounts and dates.
    private var chartData: [HistoricalDataPoint] {
        let calendar = Calendar.current
        var points: [HistoricalDataPoint] = []

        for account in activeAccounts {
            let currentBalance = account.balance
            let accountTransactions = allTransactions.filter {
                $0.account.id == account.id || $0.destinationAccount?.id == account.id
            }

            for date in dateSteps {
                let dayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
                
                // Transactions occurring AFTER this point in time needing rollback
                let futureTransactions = accountTransactions.filter { $0.timestamp > dayEnd }

                var reconstructedBalance = currentBalance

                for tx in futureTransactions {
                    switch tx.type {
                    case .expense:
                        if tx.account.id == account.id {
                            reconstructedBalance += tx.amount
                        }
                    case .income:
                        if tx.account.id == account.id {
                            reconstructedBalance -= tx.amount
                        }
                    case .transfer:
                        if tx.account.id == account.id { // Sent out
                            reconstructedBalance += tx.amount
                        } else if tx.destinationAccount?.id == account.id { // Received
                            reconstructedBalance -= tx.amount
                        }
                    }
                }

                points.append(HistoricalDataPoint(
                    date: date,
                    balance: max(0, reconstructedBalance),
                    account: account
                ))
            }
        }
        return points
    }

    private var selectedPoint: HistoricalDataPoint? {
        guard let rawSelectedDate else { return nil }
        return chartData.min(by: {
            abs($0.date.timeIntervalSince(rawSelectedDate)) < abs($1.date.timeIntervalSince(rawSelectedDate))
        })
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Controls
            HStack {
                Text("Balance History")
                    .font(.headline)

                Spacer()

                Button {
                    showAccountFilterSheet = true
                } label: {
                    Label(
                        selectedAccountIDs.isEmpty ? "All Accounts" : "\(selectedAccountIDs.count) Selected",
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }

            // Step Picker & Date Presets Bar
            HStack {
                Picker("Step", selection: $step) {
                    ForEach(TimeIntervalStep.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    showDatePickerSheet = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }

            // Selected Bar Tooltip readout
            if let point = selectedPoint {
                HStack {
                    Text(point.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(point.account.name)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(point.account.displayColor)
                    Text(point.balance, format: .currency(code: point.account.currencyCode))
                        .font(.caption)
                        .bold()
                }
                .padding(8)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }

            // Interactive Bar Chart
            Chart {
                ForEach(chartData) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: step.calendarComponent),
                        y: .value("Balance", NSDecimalNumber(decimal: point.balance).doubleValue)
                    )
                    .foregroundStyle(point.account.displayColor)
                    .position(by: .value("Account", point.account.name))
                    .cornerRadius(4)
                }

                if let rawSelectedDate {
                    RuleMark(x: .value("Selected", rawSelectedDate))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartXSelection(value: $rawSelectedDate)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: Double(dateSteps.count > 10 ? 10 * 86400 : dateSteps.count * 86400))
            .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
            .frame(height: 200)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            if selectedAccountIDs.isEmpty {
                selectedAccountIDs = Set(allAccounts.map(\.id))
            }
        }
        .sheet(isPresented: $showAccountFilterSheet) {
            accountFilterSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showDatePickerSheet) {
            dateRangeSheet
                .presentationDetents([.medium])
        }
    }

    // MARK: - Account Filter Sheet

    private var accountFilterSheet: some View {
        NavigationStack {
            List(allAccounts) { account in
                Button {
                    if selectedAccountIDs.contains(account.id) {
                        selectedAccountIDs.remove(account.id)
                    } else {
                        selectedAccountIDs.insert(account.id)
                    }
                } label: {
                    HStack {
                        Image(systemName: account.displayIcon)
                            .foregroundStyle(account.displayColor)
                        Text(account.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedAccountIDs.contains(account.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Filter Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showAccountFilterSheet = false }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Select All") {
                        selectedAccountIDs = Set(allAccounts.map(\.id))
                    }
                }
            }
        }
    }

    // MARK: - Date Range Sheet

    private var dateRangeSheet: some View {
        NavigationStack {
            Form {
                Section("Preset Ranges") {
                    Button("Last 7 Days") {
                        startDate = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
                        endDate = .now
                        showDatePickerSheet = false
                    }
                    Button("Last 30 Days") {
                        startDate = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
                        endDate = .now
                        showDatePickerSheet = false
                    }
                    Button("Last 3 Months") {
                        startDate = Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now
                        endDate = .now
                        showDatePickerSheet = false
                    }
                }

                Section("Custom Range") {
                    DatePicker("Since", selection: $startDate, displayedComponents: .date)
                    DatePicker("Up to", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDatePickerSheet = false }
                }
            }
        }
    }
}
