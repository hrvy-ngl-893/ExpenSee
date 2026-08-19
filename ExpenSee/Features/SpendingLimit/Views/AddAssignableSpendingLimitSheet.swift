//
//  AddAssignableSpendingLimitSheet.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct AddAssignableSpendingLimitSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsViewModel
    
    @Query private var categories: [SpendingCategory]
    var viewModel: SpendingLimitViewModel
    
    var existingSpendingLimit: SpendingLimit? = nil
    
    @State private var name = ""
    @State private var amountText = ""
    @State private var selectedCategory: SpendingCategory? = nil
    
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(86400 * 30) // Default 30 days
    
    @State private var isRepeating = false
    @State private var repeatFrequency: RecurrenceFrequency = .monthly
    
    private var isEditing: Bool {
        existingSpendingLimit != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Spending Limit Scope") {
                    TextField("Spending Limit Name (e.g., Vacation, Groceries)", text: $name)
                    
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
                            ForEach(RecurrenceFrequency.allCases.filter { $0 != .custom }, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
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
        guard let spendingLimit = existingSpendingLimit else { return }
        
        name = spendingLimit.name
        amountText = "\(spendingLimit.limitAmount)"
        selectedCategory = spendingLimit.category
        startDate = spendingLimit.startDate
        
        if let expDate = spendingLimit.endDate {
            hasEndDate = true
            endDate = expDate
        } else {
            hasEndDate = false
        }
        
        if let freq = spendingLimit.repeatFrequency {
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
        
        if let spendingLimit = existingSpendingLimit {
            viewModel.updateAssignableSpendingLimit(
                context: context,
                spendingLimit: spendingLimit,
                name: name,
                limitAmount: amount,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                repeatFrequency: isRepeating ? repeatFrequency : nil,
                category: selectedCategory
            )
        } else {
            viewModel.createAssignableSpendingLimit(
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
