//
//  DashboardView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore
#if os(iOS) && canImport(ActivityKit)
import ActivityKit
#endif

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel

    @Query private var records: [SpendingRecord]
    @Query(sort: \DailyBudgetRule.effectiveFrom, order: .reverse) private var rules: [DailyBudgetRule]

    @State private var remainingBudget: Decimal = 0
    @State private var spentToday: Decimal = 0
    @State private var showingEntrySheet = false
    @State private var isLiveActivityEnabled = false

    private var currentLimit: Decimal {
        rules.first(where: { $0.isCurrent })?.baseDailyLimit ?? 0
    }

    // Inverted ratio representing remaining budget percentage (1.0 = Full, 0.0 = Empty)
    private var remainingRatio: Double {
        guard currentLimit > 0 else { return 0 }
        let limitDouble = NSDecimalNumber(decimal: currentLimit).doubleValue
        let remainingDouble = NSDecimalNumber(decimal: remainingBudget).doubleValue
        return min(max(remainingDouble / limitDouble, 0), 1)
    }

    private var statusColor: Color {
        if remainingBudget < 0 {
            return .red
        } else if remainingRatio < 0.2 {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Core Visual Hero Card
                    heroBudgetCard

                    // MARK: - Key Quick Metrics
                    metricsGrid

                    // MARK: - Action Button
                    Button(action: { showingEntrySheet = true }) {
                        Label("Add Expense", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    // MARK: - Nested Navigation to Budget Rules
                    budgetNavigationTile
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Dashboard")
            .toolbar {
                #if os(iOS) && canImport(ActivityKit)
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $isLiveActivityEnabled) {
                        Label("Live Activity", systemImage: isLiveActivityEnabled ? "bell.badge.fill" : "bell")
                    }
                    .toggleStyle(.button)
                    .tint(.accentColor)
                    .onChange(of: isLiveActivityEnabled) { _, newValue in
                        handleLiveActivityToggle(enabled: newValue)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingEntrySheet) {
                EntryView()
            }
            .onAppear {
                checkLiveActivityStatus()
                updateCalculations()
            }
            .onChange(of: records) { _, _ in
                updateCalculations()
            }
        }
    }

    // MARK: - Components

    private var heroBudgetCard: some View {
        VStack(spacing: 16) {
            ZStack {
                // Track (Represents total capacity / spent portion)
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 20)

                Circle()
                    .trim(from: 0, to: CGFloat(remainingRatio))
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Core Amount Display
                VStack(spacing: 4) {
                    Text("Remaining Today")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(remainingBudget, format: .currency(code: settings.currencyCode))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(remainingBudget >= 0 ? .primary : Color.red)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text(remainingBudget < 0 ? "Over Budget" : "\(Int(remainingRatio * 100))% remaining")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .frame(width: 220)
            .frame(minHeight: 220)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    private var metricsGrid: some View {
        HStack(spacing: 20) {
            metricTile(
                title: "Spent Today",
                amount: spentToday,
                systemImage: "arrow.up.right.circle.fill",
                tint: .orange
            )

            metricTile(
                title: "Daily Limit",
                amount: currentLimit,
                systemImage: "checkmark.shield.fill",
                tint: .blue
            )
        }
    }

    private func metricTile(title: String, amount: Decimal, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(amount, format: .currency(code: settings.currencyCode))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    private var budgetNavigationTile: some View {
        NavigationLink(destination: BudgetView()) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Budget Settings")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(
                        currentLimit > 0
                            ? "Current Limit: \(currentLimit.formatted(.currency(code: settings.currencyCode)))"
                            : "No limit set"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemGroupedBackground)))
        }
    }

    // MARK: - Data & Live Activity Calculations

    private func checkLiveActivityStatus() {
        #if os(iOS) && canImport(ActivityKit)
        isLiveActivityEnabled = LiveActivityManager.shared.currentActivity != nil
        #endif
    }

    private func handleLiveActivityToggle(enabled: Bool) {
        #if os(iOS) && canImport(ActivityKit)
        if enabled {
            LiveActivityManager.shared.startActivity(
                remainingBudget: remainingBudget,
                spentToday: spentToday,
                baseDailyLimit: currentLimit
            )
        } else {
            LiveActivityManager.shared.endActivity()
        }
        #endif
    }

    private func updateCalculations() {
        let repository = SpendingRepository(context: context)
        do {
            remainingBudget = try repository.getRemainingBudget()
            
            let calendar = Calendar.current
            let todayRecords = records.filter { calendar.isDateInToday($0.timestamp) }
            spentToday = todayRecords.reduce(0) { $0 + $1.amount }

            #if os(iOS) && canImport(ActivityKit)
            if isLiveActivityEnabled {
                let lastRecord = todayRecords.sorted(by: { $0.timestamp > $1.timestamp }).first
                LiveActivityManager.shared.updateActivity(
                    remainingBudget: remainingBudget,
                    spentToday: spentToday,
                    baseDailyLimit: currentLimit,
                    lastExpenseAmount: lastRecord?.amount,
                    lastExpenseCategory: lastRecord?.category?.name
                )
            }
            #endif
        } catch {
            print("Failed to calculate budget stats: \(error)")
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(ModelContainerFactory.shared)
        .environmentObject(SettingsViewModel())
}
