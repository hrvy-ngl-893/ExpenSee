//
//  TransactionsListView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/19/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct TransactionsListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel

    @Query(sort: \ExpenSeeCore.Transaction.timestamp, order: .reverse)
    private var transactions: [ExpenSeeCore.Transaction]

    @State private var transactionToEdit: ExpenSeeCore.Transaction?
    @State private var itemPendingDeletion: ExpenSeeCore.Transaction?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if transactions.isEmpty {
                ContentUnavailableView(
                    "No Expenses Found",
                    systemImage: "creditcard.trianglebadge.exclamationmark",
                    description: Text("Added expenses will appear here.")
                )
                .padding(.vertical, 32)
            } else {
                List {
                    Section {
                        ForEach(transactions) { transaction in
                            TransactionsRow(transaction: transaction, currencyCode: settings.currencyCode)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    transactionToEdit = transaction
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        itemPendingDeletion = transaction
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        transactionToEdit = transaction
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .contextMenu {
                                    Button {
                                        transactionToEdit = transaction
                                    } label: {
                                        Label("Edit Expense", systemImage: "pencil")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        itemPendingDeletion = transaction
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete Expense", systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete(perform: deleteAtOffsets)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
        .sheet(item: $transactionToEdit) { transaction in
            TransactionEditView(transaction: transaction)
        }
        .confirmationDialog(
            "Delete Expense?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                deletePendingItem()
            }
            Button("Cancel", role: .cancel) {
                itemPendingDeletion = nil
            }
        } message: {
            if let record = itemPendingDeletion {
                Text("Are you sure you want to delete \"\(record.note.isEmpty ? "Transaction" : record.note)\"?")
            }
        }
    }

    private func deleteAtOffsets(at offsets: IndexSet) {
        for index in offsets {
            let record = transactions[index]
            context.delete(record)
        }
        try? context.save()
    }

    private func deletePendingItem() {
        guard let record = itemPendingDeletion else { return }
        context.delete(record)
        try? context.save()
        itemPendingDeletion = nil
    }
}
