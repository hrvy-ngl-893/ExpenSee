//
//  AccountsIncomeFormView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/19/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

public struct AccountsIncomeFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \SpendingCategory.name) private var categories: [SpendingCategory]
    @Query(sort: \SavingsGoal.name) private var savingsGoals: [SavingsGoal]

    private let viewModel = AccountsViewModel()

    @State private var selectedAccount: Account?
    @State private var selectedCategory: SpendingCategory?
    @State private var selectedSavingsGoal: SavingsGoal?
    @State private var amountText: String = ""
    @State private var note: String = ""

    private var initialTargetAccount: Account?

    public init(initialTargetAccount: Account? = nil) {
        self.initialTargetAccount = initialTargetAccount
    }

    private var isValid: Bool {
        guard let decimal = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")), decimal > 0 else {
            return false
        }
        return true
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Target Account & Amount
                Section("Income Details") {
                    Picker("Target Account", selection: $selectedAccount) {
                        Text("Select Account").tag(Account?.none)
                        ForEach(accounts) { account in
                            HStack {
                                Image(systemName: account.displayIcon)
                                    .foregroundStyle(account.displayColor)
                                Text(account.name)
                            }
                            .tag(Account?.some(account))
                        }
                    }

                    HStack {
                        Text(selectedAccount?.currencyCode ?? "USD")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)

                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // MARK: - Categorization & Note
                Section("Additional Info") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(SpendingCategory?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(SpendingCategory?.some(category))
                        }
                    }

                    if !savingsGoals.isEmpty {
                        Picker("Contribute to Savings Goal", selection: $selectedSavingsGoal) {
                            Text("None").tag(SavingsGoal?.none)
                            ForEach(savingsGoals) { goal in
                                Text(goal.name).tag(SavingsGoal?.some(goal))
                            }
                        }
                    }

                    TextField("Note / Source (e.g. Salary, Client)", text: $note)
                }
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIncome()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let initial = initialTargetAccount {
                    selectedAccount = initial
                } else if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
            }
        }
    }

    private func saveIncome() {
        guard let account = selectedAccount else { return }

        let success = viewModel.addIncome(
            to: account,
            amountText: amountText,
            note: note,
            category: selectedCategory,
            savingsGoal: selectedSavingsGoal,
            in: context
        )

        if success {
            dismiss()
        }
    }
}

#Preview {
    AccountsIncomeFormView()
        .modelContainer(ModelContainerFactory.inMemoryPreview)
}
