//
//  CreateCategoryView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct CreateCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "cart"
    @State private var hexColor: String = "#007AFF"
    
    var onSave: (SpendingCategory) -> Void
    
    private let availableIcons = [
        "cart", "bag", "house", "car", "bolt",
        "cross.case", "gamecontroller", "airplane",
        "creditcard", "gift", "book", "wrench"
    ]
    
    private let columns = [GridItem(.adaptive(minimum: 44))]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Info") {
                    TextField("Category Name", text: $name)
                }
                
                Section("Select Icon") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newCat = SpendingCategory(name: name.trimmingCharacters(in: .whitespaces), hexColor: hexColor, iconString: selectedIcon)
                        onSave(newCat)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
