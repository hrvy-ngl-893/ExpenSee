//
//  AccountsFormView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/17/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

public struct AccountsFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let viewModel = AccountsViewModel()
    private let accountToEdit: Account?

    @State private var name: String = ""
    @State private var balanceText: String = ""
    @State private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    @State private var selectedColor: Color = .blue
    @State private var iconString: String = "creditcard.fill"

    // Available ISO currency codes for selection
    private let availableCurrencies: [String] = Locale.commonISOCurrencyCodes.sorted()

    // Grid layout for icons
    private let columns = [GridItem(.adaptive(minimum: 44))]

    // Active iOS 17 SF Symbols tailored for financial accounts & money sources
    private let accountIcons: [String] = [
        "creditcard.fill",
        "banknote.fill",
        "building.columns.fill",
        "wallet.bifold.fill",
        "dollarsign.circle.fill",
        "eurosign.circle.fill",
        "sterlingsign.circle.fill",
        "yensign.circle.fill",
        "pesosign.circle.fill",
        "bitcoinsign.circle.fill",
        "person.fill",
        "briefcase.fill",
        "house.fill",
        "car.fill",
    ]

    public init(accountToEdit: Account? = nil) {
        self.accountToEdit = accountToEdit
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Details Section
                Section("Account Details") {
                    TextField("Account Name", text: $name)

                    Picker("Currency", selection: $currencyCode) {
                        ForEach(availableCurrencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }

                    HStack {
                        Text("Balance")
                        Spacer()
                        TextField("0.00", text: $balanceText)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                        Text(currencySymbol(for: currencyCode))
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Appearance Section
                Section("Appearance") {
                    ColorPicker("Account Color", selection: $selectedColor)
                }

                // MARK: - Icon Selection
                Section("Choose Icon") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(accountIcons, id: \.self) { symbol in
                            Button {
                                iconString = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(iconString == symbol ? selectedColor.opacity(0.15) : Color.clear)
                                    )
                                    .foregroundStyle(iconString == symbol ? selectedColor : .primary)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(iconString == symbol ? selectedColor : Color.clear, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(accountToEdit == nil ? "Add Account" : "Edit Account")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
        guard let account = accountToEdit else { return }
        name = account.name
        balanceText = "\(account.balance)"
        currencyCode = account.currencyCode
        selectedColor = account.displayColor
        iconString = account.iconString ?? "creditcard.fill"
    }

    private func saveSource() {
        let hexColor = selectedColor.toHex()

        if let accountToEdit {
            _ = viewModel.updateAccount(
                accountToEdit,
                name: name,
                balanceText: balanceText,
                currencyCode: currencyCode,
                hexColor: hexColor,
                iconString: iconString,
                in: context
            )
        } else {
            _ = viewModel.addAccount(
                name: name,
                balanceText: balanceText,
                currencyCode: currencyCode,
                hexColor: hexColor,
                iconString: iconString,
                in: context
            )
        }

        dismiss()
    }

    private func currencySymbol(for code: String) -> String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code]))
        return locale.currencySymbol ?? code
    }
}

#Preview {
    AccountsFormView()
}
