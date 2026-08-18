//
//  BudgetView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore
import WidgetKit

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var viewModel = BudgetViewModel()

    @Query(sort: \Budget.startDate, order: .reverse) private var allBudgets: [Budget]

    @State private var showingEditStandardSheet = false
    @State private var showingAddAssignableSheet = false
    @State private var selectedBudgetForEdit: Budget? = nil

    private var standardBudgets: [Budget] {
        allBudgets.filter { $0.period != .assignable && $0.isActive }
    }

    private var assignableBudgets: [Budget] {
        allBudgets.filter { $0.period == .assignable }
    }

    var body: some View {
        List {
            // MARK: - Standard Cadence Budgets
            Section {
                ForEach(standardBudgets) { budget in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(budget.period.rawValue.capitalized) Limit")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(budget.limitAmount, format: .currency(code: settings.currencyCode))
                                .font(.system(.title3, design: .rounded, weight: .bold))
                        }

                        Spacer()

                        Button("Configure") {
                            selectedBudgetForEdit = budget
                            showingEditStandardSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 2)
                }

                if standardBudgets.isEmpty {
                    ContentUnavailableView(
                        "No Standard Limits",
                        systemImage: "calendar.badge.clock",
                        description: Text("Set up a daily, weekly, or monthly baseline allowance.")
                    )
                }
            } header: {
                HStack {
                    Text("Global Period Budgets")
                    Spacer()
                    Button {
                        selectedBudgetForEdit = nil
                        showingEditStandardSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // MARK: - Custom & Category Budgets
            Section {
                ForEach(assignableBudgets) { budget in
                    Button {
                        selectedBudgetForEdit = budget
                        showingAddAssignableSheet = true
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(budget.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(budget.limitAmount, format: .currency(code: settings.currencyCode))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }

                            HStack {
                                if let category = budget.category {
                                    Label(category.name, systemImage: category.iconString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("All Categories")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let freq = budget.repeatFrequency {
                                    Text("Repeats \(freq.rawValue.capitalized)")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteAssignableBudgets)

                if assignableBudgets.isEmpty {
                    ContentUnavailableView(
                        "No Custom Allocations",
                        systemImage: "tray.fill",
                        description: Text("Create envelope-style budgets for specific categories or projects.")
                    )
                }
            } header: {
                HStack {
                    Text("Custom & Category Allocations")
                    Spacer()
                    Button {
                        selectedBudgetForEdit = nil
                        showingAddAssignableSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            } footer: {
                if !assignableBudgets.isEmpty {
                    Text("Swipe left to delete a custom allocation, or tap to edit.")
                }
            }
        }
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditStandardSheet, onDismiss: triggerWidgetSync) {
            UpdateLimitSheet(viewModel: viewModel, existingBudget: selectedBudgetForEdit)
        }
        .sheet(isPresented: $showingAddAssignableSheet, onDismiss: triggerWidgetSync) {
            AddAssignableBudgetSheet(viewModel: viewModel, existingBudget: selectedBudgetForEdit)
        }
    }

    private func deleteAssignableBudgets(offsets: IndexSet) {
        for index in offsets {
            let budget = assignableBudgets[index]
            viewModel.deleteBudget(context: context, budget: budget)
        }
        triggerWidgetSync()
    }

    private func triggerWidgetSync() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    NavigationStack {
        BudgetView()
            .modelContainer(ModelContainerFactory.shared)
            .environmentObject(SettingsViewModel())
    }
}
