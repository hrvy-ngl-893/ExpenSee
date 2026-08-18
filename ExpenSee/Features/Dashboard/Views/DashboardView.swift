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
    @Query(sort: \Budget.startDate, order: .reverse) private var allBudgets: [Budget]

    @State private var showingEntrySheet = false
    @State private var isLiveActivityEnabled = false
    
    // Store selected budget ID in UserDefaults/AppStorage so Widget Extensions can share access
    @AppStorage("selectedLiveActivityBudgetID", store: UserDefaults(suiteName: "group.com.harvy-angelo-tan.ExpenSee"))
    private var selectedBudgetIDString: String = ""

    private var activeBudgets: [Budget] {
        allBudgets.filter { $0.isActive }
    }

    // MARK: - Featured Budget Property
    private var featuredBudget: Budget? {
        if !selectedBudgetIDString.isEmpty,
           let budget = activeBudgets.first(where: { String(describing: $0.persistentModelID) == selectedBudgetIDString }) {
            return budget
        }
        
        // Explicit unwrapping steps prevent Swift type-checker confusion
        if let daily = activeBudgets.first(where: { $0.period == .daily }) { return daily }
        if let weekly = activeBudgets.first(where: { $0.period == .weekly }) { return weekly }
        if let monthly = activeBudgets.first(where: { $0.period == .monthly }) { return monthly }
        
        return activeBudgets.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Budget Selector
                    if activeBudgets.count > 1 {
                        budgetPickerSection
                    }

                    // MARK: - Hero Visual Card
                    if let featured = featuredBudget {
                        heroBudgetCard(for: featured)
                    } else {
                        emptyBudgetHero
                    }

                    // MARK: - Active Budgets Breakdown Grid
                    if !activeBudgets.isEmpty {
                        budgetMetricsSection
                    }

                    // MARK: - Primary Action Button
                    Button(action: { showingEntrySheet = true }) {
                        Label("Add Expense", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    // MARK: - Budget Management Navigation
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
                updateLiveActivity()
            }
            .onChange(of: records) { _, _ in
                updateLiveActivity()
            }
            // Update Activity when user picks a different budget
            .onChange(of: selectedBudgetIDString) { _, _ in
                restartLiveActivityForNewSelection()
            }
        }
    }

    // MARK: - Components

    private var budgetPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(activeBudgets) { budget in
                    let isSelected = featuredBudget?.persistentModelID == budget.persistentModelID
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedBudgetIDString = String(describing: budget.persistentModelID)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if let category = budget.category {
                                Image(systemName: category.iconString)
                            }
                            Text(budget.name)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func heroBudgetCard(for budget: Budget) -> some View {
        let spent = spentForBudget(budget)
        let limit = budget.limitAmount
        let remaining = limit - spent
        
        let limitDouble = NSDecimalNumber(decimal: limit).doubleValue
        let remainingDouble = NSDecimalNumber(decimal: remaining).doubleValue
        let ratio = limitDouble > 0 ? min(max(remainingDouble / limitDouble, 0), 1) : 0

        let statusColor: Color = {
            if remaining < 0 { return .red }
            if ratio < 0.2 { return .orange }
            return .green
        }()

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 20)

                Circle()
                    .trim(from: 0, to: CGFloat(ratio))
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(budget.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(remaining, format: .currency(code: settings.currencyCode))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(remaining >= 0 ? .primary : Color.red)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text(remaining < 0 ? "Over Budget" : "\(Int(ratio * 100))% remaining")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .frame(width: 220, height: 220)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    private var emptyBudgetHero: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No Active Budgets")
                .font(.headline)
            Text("Set a daily, weekly, monthly, or category budget to track spend.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    private var budgetMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Limits & Spending")
                .font(.headline)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(activeBudgets, id: \.persistentModelID) { budget in
                    BudgetMetricCard(
                        budget: budget,
                        spent: spentForBudget(budget),
                        currencyCode: settings.currencyCode
                    )
                }
            }
        }
    }

    private var budgetNavigationTile: some View {
        NavigationLink(destination: BudgetView()) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manage Budgets")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(activeBudgets.count) Active Budget\(activeBudgets.count == 1 ? "" : "s")")
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

    // MARK: - Calculations

    private func spentForBudget(_ budget: Budget) -> Decimal {
        let calendar = Calendar.current
        let now = Date()

        let filteredRecords = records.filter { record in
            if let budgetCategory = budget.category {
                guard record.category?.persistentModelID == budgetCategory.persistentModelID else {
                    return false
                }
            }

            switch budget.period {
            case .daily:
                return calendar.isDate(record.timestamp, inSameDayAs: now)
            case .weekly:
                return calendar.isDate(record.timestamp, equalTo: now, toGranularity: .weekOfYear)
            case .monthly:
                return calendar.isDate(record.timestamp, equalTo: now, toGranularity: .month)
            case .assignable:
                let afterStart = record.timestamp >= budget.startDate
                let beforeEnd = budget.endDate == nil || record.timestamp <= budget.endDate!
                return afterStart && beforeEnd
            }
        }

        return filteredRecords.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Live Activity Updates

    private func checkLiveActivityStatus() {
        #if os(iOS) && canImport(ActivityKit)
        isLiveActivityEnabled = LiveActivityManager.shared.currentActivity != nil
        #endif
    }

    private func handleLiveActivityToggle(enabled: Bool) {
        #if os(iOS) && canImport(ActivityKit)
        if enabled {
            updateLiveActivity()
        } else {
            LiveActivityManager.shared.endActivity()
        }
        #endif
    }

    private func restartLiveActivityForNewSelection() {
        #if os(iOS) && canImport(ActivityKit)
        guard isLiveActivityEnabled else { return }
        LiveActivityManager.shared.endActivity()
        updateLiveActivity()
        #endif
    }

    private func updateLiveActivity() {
        #if os(iOS) && canImport(ActivityKit)
        guard isLiveActivityEnabled, let featured = featuredBudget else { return }
        
        let spent = spentForBudget(featured)
        let remaining = featured.limitAmount - spent
        
        let calendar = Calendar.current
        let todayRecords = records.filter { calendar.isDateInToday($0.timestamp) }
        let lastRecord = todayRecords.sorted(by: { $0.timestamp > $1.timestamp }).first

        LiveActivityManager.shared.updateOrStartActivity(
            remainingBudget: remaining,
            spentToday: spent,
            baseDailyLimit: featured.limitAmount,
            budgetCycleName: featured.name, // <--- Dynamic Budget Title
            lastExpenseAmount: lastRecord?.amount,
            lastExpenseCategory: lastRecord?.category?.name
        )
        #endif
    }
}

struct BudgetMetricCard: View {
    let budget: Budget
    let spent: Decimal
    let currencyCode: String

    private var remaining: Decimal {
        budget.limitAmount - spent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let category = budget.category {
                    Image(systemName: category.iconString)
                } else {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                }
                Text(budget.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(spent, format: .currency(code: currencyCode))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                HStack {
                    Text("Limit: \(budget.limitAmount.formatted(.currency(code: currencyCode)))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text(remaining >= 0 ? "Rem: \(remaining.formatted(.currency(code: currencyCode)))" : "Over!")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(remaining >= 0 ? .secondary : Color.red)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }
}
#Preview {
    DashboardView()
        .modelContainer(ModelContainerFactory.shared)
        .environmentObject(SettingsViewModel())
}
