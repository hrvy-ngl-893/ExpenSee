//
//  TransactionView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//
//  CHANGE FROM ORIGINAL:
//  The amount row was hardcoded "Amount ($)" regardless of which account
//  was selected — confusing once accounts can be in different currencies
//  (a PHP account showing a "$" label). Now shows the selected account's
//  actual currency code, falling back to "$" only when nothing's selected
//  yet.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct TransactionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<SpendingLimit> { $0.isActive })
    private var activeSpendingLimits: [SpendingLimit]
    
    @Query private var availableAccounts: [Account]

    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: SpendingCategory? = nil
    @State private var selectedAccount: Account? = nil
    @State private var selectedSpendingLimit: SpendingLimit? = nil
    @State private var showNewCategorySheet = false

    var defaultSpendingLimit: SpendingLimit?

    init(defaultSpendingLimit: SpendingLimit? = nil) {
        self.defaultSpendingLimit = defaultSpendingLimit
    }

    var isValidToSave: Bool {
        let isAmountValid = !amountText.trimmingCharacters(in: .whitespaces).isEmpty
        return isAmountValid && selectedAccount != nil && selectedSpendingLimit != nil
    }

    private var amountFieldLabel: String {

        "Amount (\(selectedAccount?.currencyCode ?? "$"))"

    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Expense Details") {
                        // Target Spending Limit Picker
                        Picker("Budget Limit", selection: $selectedSpendingLimit) {
                            Text("Select Budget").tag(nil as SpendingLimit?)
                            ForEach(activeSpendingLimits, id: \.persistentModelID) { limit in
                                Text(limit.name).tag(limit as SpendingLimit?)
                            }
                        }

                        CategoryPickerView(
                            selectedCategory: $selectedCategory,
                            onAddNewCategory: { showNewCategorySheet = true }
                        )

                        AccountPickerView(
                            selectedAccount: $selectedAccount
                        )

                        HStack {
                            Text(amountFieldLabel)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(amountText.isEmpty ? "0.00" : amountText)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(amountText.isEmpty ? .secondary : .accentColor)
                        }

                        TextField("Details", text: $note)
                    }
                }

                #if os(iOS)
                CustomNumericKeypad(amountText: $amountText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemBackground))
                #endif
            }
            .navigationTitle("Log Spending")
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
                if selectedSpendingLimit == nil {
                    selectedSpendingLimit = defaultSpendingLimit ?? activeSpendingLimits.first
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
                  let account = selectedAccount,
                  let spendingLimit = selectedSpendingLimit else { return }

            let repository = SpendingRepository(context: context)

            do {
                try repository.logSpending(
                    amount: amount,
                    category: selectedCategory,
                    account: account,
                    spendingLimit: spendingLimit, // Explicitly pass selected spending limit
                    note: note
                )
                dismiss()
            } catch {
                print("Failed to save expense: \(error)")
            }
        }
}

// MARK: - Custom Dedicated Numeric Keypad View

struct CustomNumericKeypad: View {
    @Binding var amountText: String

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let keyLabels: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(keyLabels.flatMap { $0 }, id: \.self) { key in
                Button(action: { handleTap(key) }) {
                    Group {
                        if key == "⌫" {
                            Image(systemName: "delete.left.fill")
                                .font(.title2)
                        } else {
                            Text(key)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color(uiColor: .systemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
        }
    }

    private func handleTap(_ key: String) {
        if key == "⌫" {
            if !amountText.isEmpty {
                amountText.removeLast()
            }
        } else if key == "." {
            if !amountText.contains(".") {
                amountText += amountText.isEmpty ? "0." : "."
            }
        } else {
            // Prevent multiple leading zeroes
            if amountText == "0" {
                amountText = key
            } else {
                // Prevent entering more than 2 decimal places
                if let decimalRange = amountText.range(of: ".") {
                    let decimals = amountText[decimalRange.upperBound...]
                    if decimals.count >= 2 { return }
                }
                amountText += key
            }
        }
    }
}

#Preview {
    ContentView(showAddExpenseSheet: .constant(false))
        .modelContainer(ModelContainerFactory.inMemoryPreview)
        #if os(iOS)
        .environmentObject(LiveActivityManager.shared)
        #endif
        .environmentObject(SettingsViewModel())
}
