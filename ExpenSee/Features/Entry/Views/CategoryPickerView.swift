//
//  CategoryPickerView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//


import SwiftUI
import SwiftData
import ExpenSeeCore

struct CategoryPickerView: View {
    @Query(sort: \SpendingCategory.name) private var categories: [SpendingCategory]
    @Binding var selectedCategory: SpendingCategory?
    var onAddNewCategory: () -> Void

    var body: some View {
        Picker("Category", selection: $selectedCategory) {
            Text("None")
                .tag(nil as SpendingCategory?)

            Divider()

            ForEach(categories) { category in
                Label(category.name, systemImage: category.iconString)
                    .tag(category as SpendingCategory?)
            }
        }
        .pickerStyle(.menu)
        
        Button(action: onAddNewCategory) {
            Label("New Category", systemImage: "plus.circle")
                .font(.subheadline)
        }
    }
}
