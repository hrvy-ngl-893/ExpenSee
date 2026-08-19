//
//  TransactionView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct EntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var availableAccounts: [Account]

    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: SpendingCategory? = nil
    @State private var selectedAccount: Account? = nil
    @State private var showNewCategorySheet = false

    var isValidToSave: Bool {
        let isAmountValid = !amountText.trimmingCharacters(in: .whitespaces).isEmpty
        return isAmountValid && selectedAccount != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Details") {
                    CategoryPickerView(
                        selectedCategory: $selectedCategory,
                        onAddNewCategory: { showNewCategorySheet = true }
                    )
                    AccountPickerView(
                        selectedAccount: $selectedAccount
                    )

                    TextField("Amount ($)", text: $amountText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif

                    TextField("Note (Optional)", text: $note)
                }
            }
            .navigationTitle("Log Spending")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveExpense() }
                        .disabled(!isValidToSave)
                }
            }
            .onAppear {
                if selectedAccount == nil {
                    selectedAccount = availableAccounts.first
                }
            }
            .sheet(isPresented: $showNewCategorySheet) {
                CreateCategoryView { newCategory in
                    context.insert(newCategory)
                    try? context.save()
                    selectedCategory = newCategory
                }
            }
        }
    }

    private func saveExpense() {
        let filtered = amountText.replacingOccurrences(of: ",", with: ".")
        let cleanedText = filtered.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()

        guard let amount = Decimal(string: cleanedText), amount > 0,
              let account = selectedAccount else { return }

        let repository = SpendingRepository(context: context)

        do {
            try repository.logSpending(amount: amount, category: selectedCategory, account: account, note: note)
            dismiss()
        } catch {
            print("Failed to save expense: \(error)")
        }
    }
}

#Preview {
    ContentView(showAddExpenseSheet: .constant(false))
        .environmentObject(SettingsViewModel())
}
