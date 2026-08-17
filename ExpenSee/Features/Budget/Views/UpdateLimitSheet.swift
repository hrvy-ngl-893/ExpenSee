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
    @State private var limitText: String
    
    init(viewModel: BudgetViewModel, currentLimit: Decimal?) {
        self.viewModel = viewModel

        if let limit = currentLimit {
            _limitText = State(initialValue: "\(limit)")
        } else {
            _limitText = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("New Allowance") {
                    TextField("Base Daily Limit ($)", text: $limitText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
            }
            .navigationTitle("Set Daily Budget")
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
        
        viewModel.updateDailyLimit(context: context, newLimit: newLimit)
        dismiss()
    }
}
