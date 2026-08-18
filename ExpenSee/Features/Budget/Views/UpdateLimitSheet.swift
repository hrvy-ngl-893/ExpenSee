//
//  UpdateLimitSheet.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import ExpenSeeCore
import SwiftData

struct UpdateLimitSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var viewModel: BudgetViewModel
    let existingBudget: Budget?
    
    @State private var selectedPeriod: BudgetPeriod
    @State private var limitText: String
    
    init(viewModel: BudgetViewModel, existingBudget: Budget? = nil) {
        self.viewModel = viewModel
        self.existingBudget = existingBudget
        
        _selectedPeriod = State(initialValue: existingBudget?.period ?? .daily)
        if let limit = existingBudget?.limitAmount {
            _limitText = State(initialValue: "\(limit)")
        } else {
            _limitText = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Cadence") {
                    Picker("Period", selection: $selectedPeriod) {
                        Text("Daily").tag(BudgetPeriod.daily)
                        Text("Weekly").tag(BudgetPeriod.weekly)
                        Text("Monthly").tag(BudgetPeriod.monthly)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Allowance") {
                    TextField("Limit Amount ($)", text: $limitText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
            }
            .navigationTitle(existingBudget == nil ? "Set Budget" : "Configure Budget")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(limitText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let filtered = limitText.replacingOccurrences(of: ",", with: ".")
        let cleanedText = filtered.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        
        guard let newLimit = Decimal(string: cleanedText), newLimit > 0 else { return }
        
        viewModel.saveStandardBudget(
            context: context,
            period: selectedPeriod,
            limitAmount: newLimit,
            existingBudget: existingBudget
        )
        dismiss()
    }
}
