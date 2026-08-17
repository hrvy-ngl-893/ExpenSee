//
//  MoneySourceFormView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/17/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

public struct MoneySourceFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let viewModel = MoneySourcesViewModel()
    private let sourceToEdit: MoneySource?

    @State private var name: String = ""
    @State private var balanceText: String = ""
    @State private var selectedColor: Color = .blue
    @State private var iconString: String = "creditcard.fill"

    private let presetIcons = [
        "creditcard.fill", "banknote.fill", "building.columns.fill",
        "briefcase.fill", "bitcoinsign.circle.fill", "dollarsign.circle.fill",
        "chart.line.uptrend.xyaxis", "safe.fill"
    ]

    public init(sourceToEdit: MoneySource? = nil) {
        self.sourceToEdit = sourceToEdit
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Details Section
                Section("Source Details") {
                    TextField("Source Name", text: $name)

                    TextField("Balance", text: $balanceText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                }

                // MARK: - Style Section
                Section("Appearance") {
                    ColorPicker("Source Color", selection: $selectedColor)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon (SF Symbol Name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: iconString.isEmpty ? "questionmark.circle" : iconString)
                                .font(.title2)
                                .foregroundStyle(selectedColor)
                                .frame(width: 32)

                            TextField("e.g. creditcard.fill", text: $iconString)
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                #endif
                        }

                        // Icon Quick Presets Grid
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(presetIcons, id: \.self) { symbol in
                                    Button {
                                        iconString = symbol
                                    } label: {
                                        Image(systemName: symbol)
                                            .font(.title3)
                                            .padding(8)
                                            .background(
                                                Circle()
                                                    .fill(iconString == symbol ? selectedColor.opacity(0.2) : Color.clear)
                                            )
                                            .foregroundStyle(iconString == symbol ? selectedColor : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(sourceToEdit == nil ? "Add Money Source" : "Edit Money Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSource()
                    }
                    .bold()
                }
            }
            .onAppear(perform: loadExistingData)
        }
    }

    // MARK: - Data Setup & Actions

    private func loadExistingData() {
        guard let source = sourceToEdit else { return }
        name = source.name
        balanceText = "\(source.balance)"
        selectedColor = source.displayColor
        iconString = source.displayIcon
    }

    private func saveSource() {
        let hexColor = selectedColor.toHex()

        if let sourceToEdit {
            _ = viewModel.updateSource(
                sourceToEdit,
                name: name,
                balanceText: balanceText,
                hexColor: hexColor,
                iconString: iconString,
                in: context
            )
        } else {
            _ = viewModel.addSource(
                name: name,
                balanceText: balanceText,
                hexColor: hexColor,
                iconString: iconString,
                in: context
            )
        }

        dismiss()
    }
}
