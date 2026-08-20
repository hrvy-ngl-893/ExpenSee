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

public struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel

    @State private var viewModel = DashboardViewModel()

    @Query private var transactions: [ExpenSeeCore.Transaction]
    @Query(sort: \SpendingLimit.startDate, order: .reverse)
    private var allSpendingLimits: [SpendingLimit]

    @State private var activeSheet: FormRoute?
    @State private var itemPendingDeletion: ExpenSeeCore.Transaction?
    @State private var showDeleteConfirmation: Bool = false
    @State private var isLiveActivityEnabled: Bool = false

    @AppStorage("selectedLiveActivityBudgetID", store: UserDefaults(suiteName: "group.com.harvy-angelo-tan.ExpenSee"))
    private var selectedSpendingLimitIDString: String = ""

    private enum FormRoute: Identifiable {
        case entry
        case income
        case transfer
        case edit(ExpenSeeCore.Transaction)

        var id: String {
            switch self {
            case .entry:
                return "entry"
            case .income:
                return "income"
            case .transfer:
                return "transfer"
            case .edit(let transaction):
                return "edit_\(transaction.persistentModelID)"
            }
        }
    }

    public init() {}

    private var activeSpendingLimits: [SpendingLimit] {
        allSpendingLimits.filter { $0.isActive }
    }

    private var featuredSpendingLimit: SpendingLimit? {
        viewModel.featuredSpendingLimit(from: activeSpendingLimits, selectedIDString: selectedSpendingLimitIDString)
    }

    private var recentTransactions: [ExpenSeeCore.Transaction] {
        Array(transactions.prefix(5))
    }

    // MARK: - Body
    // NOTE: This is intentionally kept as a *thin* chain. Each modifier's closure
    // has been extracted into its own named function/property below so the type
    // checker never has to solve one enormous combined expression. If you add
    // new modifiers here, prefer pointing them at a named method rather than
    // inlining another closure directly in this chain.

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                listContent
                    .navigationTitle("Dashboard")
                    .toolbar { liveActivityToolbarContent }
                    .sheet(item: $activeSheet, content: sheetContent)
                    .onAppear(perform: handleOnAppear)
                    .onChange(of: transactions, handleTransactionsChange)
                    .onChange(of: selectedSpendingLimitIDString, handleSelectionChange)
                    .confirmationDialog(
                        "Delete Expense?",
                        isPresented: $showDeleteConfirmation,
                        titleVisibility: .visible,
                        presenting: itemPendingDeletion,
                        actions: deleteConfirmationActions,
                        message: deleteConfirmationMessage
                    )
            }

            // MARK: - Floating Action Buttons
            floatingActionOverlay
        }
    }

    // MARK: - List

    private var listContent: some View {
        List {
            // MARK: - Spending Limit Picker Section
            pickerSection

            // MARK: - Hero Spending Limit Card Section
            heroSection

            // MARK: - Active Budgets Metrics Section
            if !activeSpendingLimits.isEmpty {
                metricsSection
            }

            // MARK: - Recent Transactions Section
            transactionsSection
        }
        .safeAreaPadding(.bottom, 80)
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.insetGrouped)
        .listRowSpacing(0)
        .listSectionSpacing(.custom(16))
    }

    // MARK: - Sheet

    // DashboardView.swift
    @ViewBuilder
    private func sheetContent(for route: FormRoute) -> some View {
        switch route {
        case .entry:
            TransactionView(defaultSpendingLimit: featuredSpendingLimit)
        case .income:
            AccountsIncomeFormView()
        case .transfer:
            AccountsTransferFormView()
        case .edit(let transaction):
            TransactionEditView(transaction: transaction)
        }
    }

    // MARK: - Confirmation Dialog

    @ViewBuilder
    private func deleteConfirmationActions(for record: ExpenSeeCore.Transaction) -> some View {
        Button("Delete Permanently", role: .destructive) {
            deletePendingItem(record)
        }
        Button("Cancel", role: .cancel) {}
    }

    private func deleteConfirmationMessage(for record: ExpenSeeCore.Transaction) -> Text {
        let title = record.note.isEmpty ? "Transaction" : record.note
        return Text("Are you sure you want to delete \"\(title)\"?")
    }

    // MARK: - Sections

    @ViewBuilder
    private var pickerSection: some View {
        Section {
            VStack {
                if activeSpendingLimits.count > 1 {
                    SpendingLimitPickerView(
                        limits: activeSpendingLimits,
                        featuredID: featuredSpendingLimit?.persistentModelID,
                        selectedIDString: $selectedSpendingLimitIDString
                    )
                }
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var heroSection: some View {
        Section {
            if let featured = featuredSpendingLimit {
                heroCard(for: featured)
            } else {
                EmptyBudgetHeroView()
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    @ViewBuilder
    private func heroCard(for featured: SpendingLimit) -> some View {
        let (remaining, _): (Decimal, Decimal) = viewModel.remainingAndSpent(for: featured, context: context)
        let ratio: Double = viewModel.progressRatio(remaining: remaining, limit: featured.limitAmount)
        let statusColor: Color = viewModel.statusColor(remaining: remaining, ratio: ratio)

        HeroSpendingLimitCard(
            spendingLimit: featured,
            remaining: remaining,
            ratio: ratio,
            statusColor: statusColor
        )
    }

    @ViewBuilder
    private var metricsSection: some View {
        Section {
            unifiedBudgetMetricsGrid
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    @ViewBuilder
    private var transactionsSection: some View {
        Section(header: Text("Recent Transactions")) {
            if transactions.isEmpty {
                ContentUnavailableView(
                    "No Expenses Found",
                    systemImage: "creditcard.trianglebadge.exclamationmark",
                    description: Text("Added expenses will appear here.")
                )
                .padding(.vertical, 32)
            } else {
                ForEach(recentTransactions) { transaction in
                    TransactionsRow(
                        transaction: transaction,
                        currencyCode: settings.currencyCode,
                        onEdit: {
                            activeSheet = .edit(transaction)
                        },
                        onDelete: {
                            confirmDelete(transaction)
                        }
                    )
                }
                .onDelete(perform: deleteAtOffsets)
            }
        }
    }

    // MARK: - Subviews & Controls

    private var unifiedBudgetMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(activeSpendingLimits, id: \.persistentModelID) { limit in
                budgetCard(for: limit)
            }
        }
    }

    @ViewBuilder
    private func budgetCard(for limit: SpendingLimit) -> some View {
        let (remaining, spent): (Decimal, Decimal) = viewModel.remainingAndSpent(for: limit, context: context)

        UnifiedBudgetCard(
            spendingLimit: limit,
            spent: spent,
            remaining: remaining
        )
    }

    private var floatingActionOverlay: some View {
        HStack(spacing: 16) {
            addIncomeButton
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
            addTransferButton
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
            addExpenseButton
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .padding(20)
    }

    private var addExpenseButton: some View {
        Button(action: { activeSheet = .entry }) {
            Label("Expense", systemImage: "arrow.up.circle")
                .font(.caption)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .tint(.red)
    }

    private var addIncomeButton: some View {
        Button(action: { activeSheet = .income }) {
            Label("Income", systemImage: "arrow.down.circle")
                .font(.caption)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .tint(.green)
    }

    private var addTransferButton: some View {
        Button(action: { activeSheet = .transfer }) {
            Label("Transfer", systemImage: "arrow.left.arrow.right")
                .font(.caption)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .tint(.orange)
    }

    @ToolbarContentBuilder
    private var liveActivityToolbarContent: some ToolbarContent {
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

    // MARK: - Data Actions

    private func confirmDelete(_ transaction: ExpenSeeCore.Transaction) {
        itemPendingDeletion = transaction
        showDeleteConfirmation = true
    }

    private func deleteAtOffsets(at offsets: IndexSet) {
        for index in offsets {
            guard index < recentTransactions.count else { continue }
            let record = recentTransactions[index]
            context.delete(record)
        }
        try? context.save()
    }

    private func deletePendingItem(_ record: ExpenSeeCore.Transaction) {
        context.delete(record)
        try? context.save()
    }

    // MARK: - Lifecycle / Change Handlers
    // Pulled out of the `body` chain (rather than inlined as `{ _, _ in ... }`
    // closures) so each has an explicit, independently-checked signature.

    private func handleOnAppear() {
        checkLiveActivityStatus()
        updateLiveActivity()
    }

    private func handleTransactionsChange(
        _ oldValue: [ExpenSeeCore.Transaction],
        _ newValue: [ExpenSeeCore.Transaction]
    ) {
        updateLiveActivity()
    }

    private func handleSelectionChange(_ oldValue: String, _ newValue: String) {
        restartLiveActivityForNewSelection()
    }

    // MARK: - Live Activity Handlers

    private func checkLiveActivityStatus() {
#if os(iOS) && canImport(ActivityKit)
        let isActive = LiveActivityManager.shared.currentActivity?.activityState == .active
        if isLiveActivityEnabled != isActive {
            isLiveActivityEnabled = isActive
        }
#endif
    }

    private func handleLiveActivityToggle(enabled: Bool) {
#if os(iOS) && canImport(ActivityKit)
        if enabled {
            updateLiveActivity()
        } else {
            viewModel.endLiveActivity()
        }
#endif
    }

    private func restartLiveActivityForNewSelection() {
#if os(iOS) && canImport(ActivityKit)
        guard isLiveActivityEnabled else { return }
        viewModel.endLiveActivity()
        updateLiveActivity()
#endif
    }

    private func updateLiveActivity() {
#if os(iOS) && canImport(ActivityKit)
        guard isLiveActivityEnabled, let featured = featuredSpendingLimit else { return }
        let calendar = Calendar.current
        let todaysTransactions = transactions.filter { calendar.isDateInToday($0.timestamp) }

        viewModel.startOrUpdateLiveActivity(
            for: featured,
            context: context,
            todaysTransactions: todaysTransactions,
            currencyCode: featured.currencyCode
        )
#endif
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .modelContainer(ModelContainerFactory.inMemoryPreview)
            .environmentObject(SettingsViewModel())
    }
}
