//
//  AccountsView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

public struct AccountsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel

    @Query(sort: \Account.name) private var accounts: [Account]

    private let viewModel = AccountsViewModel()

    @State private var activeSheet: FormRoute?
    @State private var accountToDelete: Account?
    @State private var showDeleteConfirmation: Bool = false

    private enum FormRoute: Identifiable {
        case add
        case edit(Account)
        case transfer(source: Account?)
        case income(target: Account?)

        var id: String {
            switch self {
            case .add:
                return "add"
            case .edit(let account):
                return "edit_\(account.id.uuidString)"
            case .transfer(let account):
                return "transfer_\(account?.id.uuidString ?? "general")"
            case .income(let account):
                return "income_\(account?.id.uuidString ?? "general")"
            }
        }
    }

    public init() {}

    private var totalBalance: Decimal {
        accounts.reduce(0) { $0 + $1.balance }
    }

    public var body: some View {
        NavigationStack {
            List {
                // MARK: - Header (Total Balance + Pie Chart)
                Section {
                    VStack() {
                        AccountsChartView()
                            .frame(minHeight: 180)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                // MARK: - Money Sources List
                Section {
                    ForEach(accounts) { account in
                        accountRow(account)
                    }
                    .onDelete(perform: deleteAccounts)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button(action: { activeSheet = .income(target: nil) }) {
                        Label("Add Income", systemImage: "arrow.down.circle")
                    }
                    .disabled(accounts.isEmpty)
                    .tint(.green)

                    Button(action: { activeSheet = .transfer(source: nil) }) {
                        Label("Transfer", systemImage: "arrow.left.arrow.right")
                    }
                    .disabled(accounts.count < 2)

                    Button(action: { activeSheet = .add }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { route in
                switch route {
                case .add:
                    AccountsFormView()
                        .presentationDetents([.medium, .large])
                case .edit(let account):
                    AccountsFormView(accountToEdit: account)
                        .presentationDetents([.medium, .large])
                case .transfer(let sourceAccount):
                    AccountsTransferFormView(initialSourceAccount: sourceAccount)
                        .presentationDetents([.medium, .large])
                case .income(let targetAccount):
                    AccountsIncomeFormView(initialTargetAccount: targetAccount)
                        .presentationDetents([.medium, .large])
                }
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible,
                presenting: accountToDelete
            ) { account in
                Button("Delete \(account.name)", role: .destructive) {
                    viewModel.delete(account, from: context)
                }
                Button("Cancel", role: .cancel) {}
            } message: { account in
                Text("Are you sure you want to delete this account? This action cannot be undone.")
            }
        }
    }

    // MARK: - Components

    private func accountRow(_ account: Account) -> some View {
        HStack(spacing: 12) {
            Image(systemName: account.displayIcon)
                .font(.title2)
                .foregroundStyle(account.displayColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text(account.balance, format: .currency(code: account.currencyCode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            activeSheet = .edit(account)
        }
        // Example: Splitting across edges in AccountsView
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { confirmDelete(account) } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { activeSheet = .edit(account) } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading) {
            Button { activeSheet = .income(target: account) } label: {
                Label("Income", systemImage: "arrow.down.circle")
            }
            .tint(.green)
            
            Button { activeSheet = .transfer(source: account) } label: {
                Label("Transfer", systemImage: "arrow.left.arrow.right")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button {
                activeSheet = .income(target: account)
            } label: {
                Label("Add Income", systemImage: "arrow.down.circle")
            }

            Button {
                activeSheet = .transfer(source: account)
            } label: {
                Label("Transfer Funds", systemImage: "arrow.left.arrow.right")
            }

            Button {
                activeSheet = .edit(account)
            } label: {
                Label("Edit Source", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                confirmDelete(account)
            } label: {
                Label("Delete Account", systemImage: "trash")
            }
        }
    }

    // MARK: - Data Actions

    private func confirmDelete(_ account: Account) {
        accountToDelete = account
        showDeleteConfirmation = true
    }

    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            viewModel.delete(accounts[index], from: context)
        }
    }
}

#Preview {
    NavigationStack {
        AccountsView()
            .modelContainer(ModelContainerFactory.inMemoryPreview)
            .environmentObject(SettingsViewModel())
    }
}
