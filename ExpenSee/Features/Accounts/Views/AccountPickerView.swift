//
//  AccountPickerView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct AccountPickerView: View {
    @Query(sort: \Account.name) private var accounts: [Account]
    @Binding var selectedAccount: Account?

    var body: some View {
        Picker("Account", selection: $selectedAccount) {
            Text("None")
                .tag(nil as Account?)

            Divider()

            ForEach(accounts) { account in
                Label(account.name, systemImage: "wallet.bifold")
                    .tag(account as Account?)
            }
        }
        .pickerStyle(.menu)
    }
}
