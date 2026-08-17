//
//  BudgetView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var viewModel = BudgetViewModel()

    @Query(sort: \DailyBudgetRule.effectiveFrom, order: .reverse) private var allRules: [DailyBudgetRule]

    @State private var showingEditSheet = false

    private var currentRule: DailyBudgetRule? {
        allRules.first(where: { $0.isCurrent })
    }

    private var historicalRules: [DailyBudgetRule] {
        allRules.filter { !$0.isCurrent }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Daily Budget")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let current = currentRule {
                            Text(current.baseDailyLimit, format: .currency(code: settings.currencyCode))
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                        } else {
                            Text("Not Configured")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        showingEditSheet = true
                    } label: {
                        Text(currentRule == nil ? "Set Limit" : "Configure")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Current Allocation")
            }

            if !historicalRules.isEmpty {
                Section {
                    ForEach(historicalRules) { rule in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.baseDailyLimit, format: .currency(code: settings.currencyCode))
                                    .font(.headline)
                                Text("Effective: \(rule.effectiveFrom.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete(perform: deleteHistoricalRules)
                } header: {
                    Text("Budget History")
                } footer: {
                    Text("Swipe left to delete previous budget rules.")
                }
            }
        }
        .navigationTitle("Daily Budget")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            UpdateLimitSheet(viewModel: viewModel, currentLimit: currentRule?.baseDailyLimit)
        }
    }

    private func deleteHistoricalRules(offsets: IndexSet) {
        for index in offsets {
            let rule = historicalRules[index]
            viewModel.deleteRule(context: context, rule: rule)
        }
    }
}

#Preview {
    NavigationStack {
        BudgetView()
            .modelContainer(ModelContainerFactory.shared)
            .environmentObject(SettingsViewModel())
    }
}
