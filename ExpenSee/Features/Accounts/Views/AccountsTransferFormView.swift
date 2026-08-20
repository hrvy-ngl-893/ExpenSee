//
//  TransferFormView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/19/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

public struct AccountsTransferFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel

    @Query(sort: \Account.name) private var accounts: [Account]

    @State private var sourceAccount: Account?
    @State private var destinationAccount: Account?
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var errorMessage: String?

    private let viewModel = AccountsViewModel()

    public init(initialSourceAccount: Account? = nil) {
        _sourceAccount = State(initialValue: initialSourceAccount)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Transfer Details") {
                    Picker("From", selection: $sourceAccount) {
                        Text("Select Account").tag(Account?.none)
                        ForEach(accounts) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }

                    Picker("To", selection: $destinationAccount) {
                        Text("Select Account").tag(Account?.none)
                        ForEach(accounts.filter { $0.id != sourceAccount?.id }) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    TextField("Details", text: $note)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.body)
                    }
                }
            }
            .navigationTitle("Transfer Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") {
                        performTransfer()
                    }
                    .bold()
                    .disabled(amountText == "")
                }
            }
            .onAppear {
                if sourceAccount == nil {
                    sourceAccount = accounts.first
                }
                if destinationAccount == nil {
                    destinationAccount = accounts.first(where: { $0.id != sourceAccount?.id })
                }
            }
        }
    }

    private func performTransfer() {
        guard let source = sourceAccount, let destination = destinationAccount else {
            errorMessage = "Please select both a source and destination account."
            return
        }

        let success = viewModel.transfer(
            from: source,
            to: destination,
            amountText: amountText,
            note: note,
            in: context
        )

        if success {
            dismiss()
        } else {
            errorMessage = "Invalid amount or insufficient balance."
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
