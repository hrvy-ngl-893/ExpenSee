//
//  SpendingLimitUpdateSheet.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import ExpenSeeCore
import SwiftData

struct SpendingLimitUpdateSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var viewModel: SpendingLimitViewModel
    let existingSpendingLimit: SpendingLimit?
    
    @State private var selectedFrequency: RecurrenceFrequency
    @State private var limitText: String
    
    init(viewModel: SpendingLimitViewModel, existingSpendingLimit: SpendingLimit? = nil) {
        self.viewModel = viewModel
        self.existingSpendingLimit = existingSpendingLimit
        
        _selectedFrequency = State(initialValue: existingSpendingLimit?.period ?? .daily)
        if let limit = existingSpendingLimit?.limitAmount {
            _limitText = State(initialValue: "\(limit)")
        } else {
            _limitText = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Cadence") {
                    Picker("Period", selection: $selectedFrequency) {
                        ForEach(RecurrenceFrequency.allCases.filter { $0 != .custom }, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Allowance") {
                    TextField("Limit Amount ($)", text: $limitText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
            }
            .navigationTitle(existingSpendingLimit == nil ? "Set Spending Limit" : "Configure Spending Limit")
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
        
        viewModel.saveStandardSpendingLimit(
            context: context,
            period: selectedFrequency,
            limitAmount: newLimit,
            existingLimit: existingSpendingLimit
        )
        dismiss()
    }
}
