//
//  AddOverrideView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct AddOverrideView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var viewModel: BudgetViewModel
    
    @State private var selectedDate = Date()
    @State private var amountText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Override Details") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
                    HStack {
                        Text("Limit")
                        Spacer()
                        TextField("Amount", text: $amountText)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
            }
            .navigationTitle("New Override")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(amountText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let filtered = amountText.replacingOccurrences(of: ",", with: ".")
        let cleanedText = filtered.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        
        guard let amount = Decimal(string: cleanedText), amount >= 0 else { return }
        
        viewModel.updateDailyLimit(context: context, newLimit: amount)
        dismiss()
    }
}
