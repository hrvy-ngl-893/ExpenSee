//
//  SpendingLimitView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore
import WidgetKit

struct SpendingLimitView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var viewModel = SpendingLimitViewModel()

    @Query(sort: \SpendingLimit.startDate, order: .reverse) private var allSpendingLimits: [SpendingLimit]

    @State private var showingEditStandardSheet = false
    @State private var showingAddAssignableSheet = false
    @State private var selectedSpendingLimitForEdit: SpendingLimit? = nil

    private var standardSpendingLimits: [SpendingLimit] {
        allSpendingLimits.filter { $0.period != .custom && $0.isActive }
    }

    private var customSpendingLimits: [SpendingLimit] {
        allSpendingLimits.filter { $0.period == .custom }
    }

    var body: some View {
        List {
            // MARK: - Standard Cadence SpendingLimits
            Section {
                ForEach(standardSpendingLimits) { spendingLimit in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(spendingLimit.period.rawValue.capitalized) Limit")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(spendingLimit.limitAmount, format: .currency(code: settings.currencyCode))
                                .font(.system(.title3, design: .rounded, weight: .bold))
                        }

                        Spacer()

                        Button("Configure") {
                            selectedSpendingLimitForEdit = spendingLimit
                            showingEditStandardSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 2)
                }

                if standardSpendingLimits.isEmpty {
                    ContentUnavailableView(
                        "No Standard Limits",
                        systemImage: "calendar.badge.clock",
                        description: Text("Set up a daily, weekly, or monthly baseline allowance.")
                    )
                }
            } header: {
                HStack {
                    Text("Global Period SpendingLimits")
                    Spacer()
                    Button {
                        selectedSpendingLimitForEdit = nil
                        showingEditStandardSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // MARK: - Custom & Category SpendingLimits
            Section {
                ForEach(customSpendingLimits) { spendingLimit in
                    Button {
                        selectedSpendingLimitForEdit = spendingLimit
                        showingAddAssignableSheet = true
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(spendingLimit.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(spendingLimit.limitAmount, format: .currency(code: settings.currencyCode))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }

                            HStack {
                                if let category = spendingLimit.category {
                                    Label(category.name, systemImage: category.iconString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("All Categories")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let freq = spendingLimit.repeatFrequency {
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
                .onDelete(perform: deleteAssignableSpendingLimits)

                if customSpendingLimits.isEmpty {
                    ContentUnavailableView(
                        "No Custom Allocations",
                        systemImage: "tray.fill",
                        description: Text("Create envelope-style spending limits for specific categories or projects.")
                    )
                }
            } header: {
                HStack {
                    Text("Custom & Category Allocations")
                    Spacer()
                    Button {
                        selectedSpendingLimitForEdit = nil
                        showingAddAssignableSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            } footer: {
                if !customSpendingLimits.isEmpty {
                    Text("Swipe left to delete a custom allocation, or tap to edit.")
                }
            }
        }
        .navigationTitle("Spending Limits")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingEditStandardSheet, onDismiss: triggerWidgetSync) {
            SpendingLimitUpdateSheet(viewModel: viewModel, existingSpendingLimit: selectedSpendingLimitForEdit)
        }
        .sheet(isPresented: $showingAddAssignableSheet, onDismiss: triggerWidgetSync) {
            AddAssignableSpendingLimitSheet(viewModel: viewModel, existingSpendingLimit: selectedSpendingLimitForEdit)
        }
    }

    private func deleteAssignableSpendingLimits(offsets: IndexSet) {
        for index in offsets {
            let spendingLimit = customSpendingLimits[index]
            viewModel.deleteSpendingLimit(context: context, spendingLimit: spendingLimit)
        }
        triggerWidgetSync()
    }

    private func triggerWidgetSync() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    NavigationStack {
        SpendingLimitView()
            .modelContainer(ModelContainerFactory.shared)
            .environmentObject(SettingsViewModel())
    }
}
