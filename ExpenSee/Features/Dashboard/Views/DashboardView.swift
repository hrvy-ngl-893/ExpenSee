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

    @Query private var transactions: [ExpenSeeCore.Transaction]
    @Query(sort: \SpendingLimit.startDate, order: .reverse) private var allSpendingLimits: [SpendingLimit]

    @State private var showingEntrySheet = false
    @State private var isLiveActivityEnabled = false

    @AppStorage("selectedLiveActivityBudgetID", store: UserDefaults(suiteName: "group.com.harvy-angelo-tan.ExpenSee"))
    private var selectedSpendingLimitIDString: String = ""

    private var activeSpendingLimits: [SpendingLimit] {
        allSpendingLimits.filter { $0.isActive }
    }
    
    private var featuredSpendingLimit: SpendingLimit? {
        if !selectedSpendingLimitIDString.isEmpty,
           let budget = activeSpendingLimits.first(where: { String(describing: $0.persistentModelID) == selectedSpendingLimitIDString }) {
            return budget
        }
        
        // Priority fallbacks
        if let daily = activeSpendingLimits.first(where: { $0.period == .daily }) {
            return daily
        }
        if let weekly = activeSpendingLimits.first(where: { $0.period == .weekly }) {
            return weekly
        }
        if let quincena = activeSpendingLimits.first(where: { $0.period == .quincena }) {
            return quincena
        }
        if let monthly = activeSpendingLimits.first(where: { $0.period == .monthly }) {
            return monthly
        }
        if let yearly = activeSpendingLimits.first(where: { $0.period == .yearly }) {
            return yearly
        }
        
        return activeSpendingLimits.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if activeSpendingLimits.count > 1 {
                        spendingLimitPickerSection
                    }

                    if let featured = featuredSpendingLimit {
                        heroSpendingLimitCard(for: featured)
                    } else {
                        emptyBudgetHero
                    }

                    if !activeSpendingLimits.isEmpty {
                        budgetMetricsSection
                    }

                    addExpenseButton

                    budgetNavigationTile

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Expenses")
                            .font(.headline)
                            .padding(.leading, 4)

                        TransactionsListView()
                    }
                }
                .padding()
            }
            .background(.secondary.opacity(0.1))
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
            .onChange(of: transactions) { _, _ in
                updateLiveActivity()
            }
            .onChange(of: selectedSpendingLimitIDString) { _, _ in
                restartLiveActivityForNewSelection()
            }
        }
    }

    // MARK: - Components

    private var spendingLimitPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(activeSpendingLimits, id: \.persistentModelID) { spendingLimit in
                    let isSelected = featuredSpendingLimit?.persistentModelID == spendingLimit.persistentModelID
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSpendingLimitIDString = String(describing: spendingLimit.persistentModelID)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if let category = spendingLimit.category {
                                Image(systemName: category.iconString)
                            }
                            Text(spendingLimit.name)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.accentColor : Color.gray.opacity(0.15), in: Capsule())
                        .foregroundStyle(isSelected ? .white : .primary)
                    }
                }
            }
        }
    }

    private func heroSpendingLimitCard(for spendingLimit: SpendingLimit) -> some View {
        let spent = spentForSpendingLimit(spendingLimit)
        let limit = spendingLimit.limitAmount
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
                    Text(spendingLimit.name)
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var budgetMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Limits & Spending")
                .font(.headline)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(activeSpendingLimits, id: \.persistentModelID) { spendingLimit in
                    SpendingLimitMetricCard(
                        spendingLimit: spendingLimit,
                        spent: spentForSpendingLimit(spendingLimit),
                        currencyCode: settings.currencyCode
                    )
                }
            }
        }
    }

    private var addExpenseButton: some View {
        Button(action: { showingEntrySheet = true }) {
            Label("Add Expense", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var budgetNavigationTile: some View {
        NavigationLink(destination: SpendingLimitView()) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manage Budgets")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(activeSpendingLimits.count) Active Budget\(activeSpendingLimits.count == 1 ? "" : "s")")
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
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Calculations

    private func spentForSpendingLimit(_ spendingLimit: SpendingLimit) -> Decimal {
        let calendar = Calendar.current
        let now = Date()

        let filteredTransactions = transactions.filter { transaction in
            if let limitCategory = spendingLimit.category {
                guard transaction.category?.persistentModelID == limitCategory.persistentModelID else {
                    return false
                }
            }

            let date = transaction.timestamp

            switch spendingLimit.period {
            case .daily:
                return calendar.isDate(date, inSameDayAs: now)

            case .weekly:
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) &&
                       calendar.isDate(date, equalTo: now, toGranularity: .yearForWeekOfYear)

            case .quincena:
                guard calendar.isDate(date, equalTo: now, toGranularity: .month) &&
                      calendar.isDate(date, equalTo: now, toGranularity: .year) else {
                    return false
                }
                let nowDay = calendar.component(.day, from: now)
                let transactionDay = calendar.component(.day, from: date)
                return (nowDay <= 15 && transactionDay <= 15) || (nowDay > 15 && transactionDay > 15)

            case .monthly:
                return calendar.isDate(date, equalTo: now, toGranularity: .month) &&
                       calendar.isDate(date, equalTo: now, toGranularity: .year)

            case .yearly:
                return calendar.isDate(date, equalTo: now, toGranularity: .year)

            case .custom:
                let afterStart = date >= spendingLimit.startDate
                let beforeEnd = spendingLimit.endDate == nil || date <= spendingLimit.endDate!
                return afterStart && beforeEnd
            }
        }

        return filteredTransactions.reduce(0) { $0 + $1.amount }
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
        guard isLiveActivityEnabled, let featured = featuredSpendingLimit else { return }
        
        let spent = spentForSpendingLimit(featured)
        let remaining = featured.limitAmount - spent
        
        let calendar = Calendar.current
        let todayRecords = transactions.filter { calendar.isDateInToday($0.timestamp) }
        let lastRecord = todayRecords.sorted(by: { $0.timestamp > $1.timestamp }).first

        LiveActivityManager.shared.updateOrStartActivity(
            remainingBudget: remaining,
            spentToday: spent,
            baseDailyLimit: featured.limitAmount,
            budgetCycleName: featured.name,
            currencyCode: settings.currencyCode,
            lastExpenseAmount: lastRecord?.amount,
            lastExpenseCategory: lastRecord?.category?.name
        )
        #endif
    }
}

#Preview {
    DashboardView()
        .modelContainer(ModelContainerFactory.shared)
        .environmentObject(SettingsViewModel())
}
