//
//  TransactionEditView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/19/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct TransactionEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsViewModel

    @Bindable var transaction: ExpenSeeCore.Transaction

    @Query private var categories: [SpendingCategory]
    @Query private var accounts: [Account]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Amount", value: $transaction.amount, format: .currency(code: settings.currencyCode))
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif

                    TextField("Note", text: $transaction.note)

                    DatePicker("Date", selection: $transaction.timestamp, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Classification") {
                    Picker("Category", selection: $transaction.category) {
                        Text("None").tag(nil as SpendingCategory?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as SpendingCategory?)
                        }
                    }

                    Picker("Money Source", selection: $transaction.account) {
                        Text("None").tag(nil as Account?)
                        ForEach(accounts) { account in
                            Text(account.name).tag(account as Account?)
                        }
                    }
                }
            }
            .navigationTitle("Edit Expense")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TransactionsListView()
            .modelContainer(ModelContainerFactory.inMemoryPreview)
            .environmentObject(SettingsViewModel())
    }
}
