//
//  AddAssignableBudgetSheet.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct AddAssignableBudgetSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsViewModel
    
    @Query private var categories: [SpendingCategory]
    var viewModel: BudgetViewModel
    
    var existingBudget: Budget? = nil
    
    @State private var name = ""
    @State private var amountText = ""
    @State private var selectedCategory: SpendingCategory? = nil
    
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(86400 * 30) // Default 30 days
    
    @State private var isRepeating = false
    @State private var repeatFrequency: PaymentFrequency = .monthly
    
    private var isEditing: Bool {
        existingBudget != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Scope") {
                    TextField("Budget Name (e.g., Vacation, Groceries)", text: $name)
                    
                    Picker("Category (Optional)", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as SpendingCategory?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as SpendingCategory?)
                        }
                    }
                    
                    HStack {
                        Text("Limit")
                        Spacer()
                        TextField("Amount (\(settings.currencyCode))", text: $amountText)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
                
                Section("Duration") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    Toggle("Set End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
                
                Section("Recurrence") {
                    Toggle("Repeat Budget", isOn: $isRepeating)
                    
                    if isRepeating {
                        Picker("Frequency", selection: $repeatFrequency) {
                            Text("Daily").tag(PaymentFrequency.daily)
                            Text("Weekly").tag(PaymentFrequency.weekly)
                            Text("Monthly").tag(PaymentFrequency.monthly)
                            Text("Yearly").tag(PaymentFrequency.yearly)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Custom Budget" : "New Custom Budget")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") { save() }
                        .disabled(amountText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: populateExistingData)
        }
    }
    
    private func populateExistingData() {
        guard let budget = existingBudget else { return }
        
        name = budget.name
        amountText = "\(budget.limitAmount)"
        selectedCategory = budget.category
        startDate = budget.startDate
        
        if let expDate = budget.endDate {
            hasEndDate = true
            endDate = expDate
        } else {
            hasEndDate = false
        }
        
        if let freq = budget.repeatFrequency {
            isRepeating = true
            repeatFrequency = freq
        } else {
            isRepeating = false
        }
    }
    
    private func save() {
        let filtered = amountText.replacingOccurrences(of: ",", with: ".")
        let cleanedText = filtered.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        
        guard let amount = Decimal(string: cleanedText), amount > 0 else { return }
        
        if let budget = existingBudget {
            viewModel.updateAssignableBudget(
                context: context,
                budget: budget,
                name: name,
                limitAmount: amount,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                repeatFrequency: isRepeating ? repeatFrequency : nil,
                category: selectedCategory
            )
        } else {
            viewModel.createAssignableBudget(
                context: context,
                name: name,
                limitAmount: amount,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                repeatFrequency: isRepeating ? repeatFrequency : nil,
                category: selectedCategory
            )
        }
        
        dismiss()
    }
}
