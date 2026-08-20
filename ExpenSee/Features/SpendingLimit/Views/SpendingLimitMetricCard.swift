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
    let explicitCurrencyCode: String?

    init(
        spendingLimit: SpendingLimit,
        spent: Decimal,
        currencyCode: String? = nil
    ) {
        self.spendingLimit = spendingLimit
        self.spent = spent
        self.explicitCurrencyCode = currencyCode
    }

    /// Resolves currency code from the model hierarchy first, then explicit input, then locale fallback
    private var resolvedCurrencyCode: String {
        if !spendingLimit.currencyCode.isEmpty {
            return spendingLimit.currencyCode
        } else if let accountCurrency = spendingLimit.account?.currencyCode, !accountCurrency.isEmpty {
            return accountCurrency
        } else if let explicitCurrencyCode, !explicitCurrencyCode.isEmpty {
            return explicitCurrencyCode
        } else {
            return Locale.current.currency?.identifier ?? "USD"
        }
    }
    
    private var remaining: Decimal {
        spendingLimit.limitAmount - spent
    }

    private var progressRatio: Double {
        guard spendingLimit.limitAmount > 0 else { return 0 }
        let ratio = (spent as NSDecimalNumber).doubleValue / (spendingLimit.limitAmount as NSDecimalNumber).doubleValue
        return min(max(ratio, 0.0), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if spendingLimit.categories.count > 1 {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(.primary)
                } else if let category = spendingLimit.categories.first {
                    Image(systemName: category.iconString)
                        .foregroundStyle(.primary)
                } else {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                }

                Text(spendingLimit.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                if let accountName = spendingLimit.account?.name {
                    Text(accountName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(.tertiarySystemFill)))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(spent, format: .currency(code: resolvedCurrencyCode))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                ProgressView(value: progressRatio)
                    .tint(remaining < 0 ? .red : .accentColor)
                    .padding(.vertical, 2)

                HStack {
                    Text("Limit: \(spendingLimit.limitAmount.formatted(.currency(code: resolvedCurrencyCode)))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Text(remaining >= 0 ? "Rem: \(remaining.formatted(.currency(code: resolvedCurrencyCode)))" : "Over!")
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
