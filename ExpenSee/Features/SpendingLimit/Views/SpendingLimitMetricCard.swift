//
//  SpendingLimitMetricCard.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/19/26.
//

import SwiftUI
import ExpenSeeCore

struct SpendingLimitMetricCard: View {
    let spendingLimit: SpendingLimit
    let spent: Decimal
    let currencyCode: String

    private var remaining: Decimal {
        spendingLimit.limitAmount - spent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let category = spendingLimit.category {
                    Image(systemName: category.iconString)
                } else {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                }
                Text(spendingLimit.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(spent, format: .currency(code: currencyCode))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                HStack {
                    Text("Limit: \(spendingLimit.limitAmount.formatted(.currency(code: currencyCode)))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text(remaining >= 0 ? "Rem: \(remaining.formatted(.currency(code: currencyCode)))" : "Over!")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(remaining >= 0 ? .secondary : Color.red)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemFill)))
    }
}
