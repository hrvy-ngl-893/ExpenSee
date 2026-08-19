//
//  TransactionsRow.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/19/26.
//

import SwiftUI
import ExpenSeeCore

struct TransactionsRow: View {
    let transaction: ExpenSeeCore.Transaction
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            categoryIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note.isEmpty ? "Expense" : transaction.note)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text(transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                    Text("•")
                    Text(transaction.account.name)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(transaction.amount, format: .currency(code: currencyCode))
                .font(.callout)
                .fontWeight(.bold)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemFill)))
    }

    @ViewBuilder
    private var categoryIcon: some View {
        if let category = transaction.category {
            Image(systemName: category.iconString)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: category.hexColor) ?? .accentColor)
                .clipShape(Circle())
        } else {
            Image(systemName: "cart.fill")
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())
        }
    }
}
