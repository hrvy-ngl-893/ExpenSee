//
//  AccountsChartView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import Charts
import SwiftData
import ExpenSeeCore

public struct AccountsChartView: View {
    @EnvironmentObject private var settings: SettingsViewModel
    @Query(sort: \Account.name) private var sources: [Account]

    public init() {}

    /// Groups accounts by currency code and calculates the sum for each currency.
    private var totalsByCurrency: [(code: String, total: Decimal)] {
        let dictionary = Dictionary(grouping: sources, by: \.currencyCode)
        return dictionary.map { key, accounts in
            let sum = accounts.reduce(0) { $0 + $1.balance }
            return (code: key, total: sum)
        }
        .sorted { $0.code < $1.code }
    }

    public var body: some View {
        VStack(spacing: 16) {
            heroChartCard
        }
    }

    // MARK: - Components

    private var heroChartCard: some View {
        ZStack {
            Chart(sources) { source in
                SectorMark(
                    angle: .value("Balance", NSDecimalNumber(decimal: source.balance).doubleValue),
                    innerRadius: .ratio(0.65),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(source.displayColor)
            }
            .chartLegend(position: .bottom, alignment: .center, spacing: 12)
            .frame(height: 220)

            // Core Amount Display
            VStack(spacing: 2) {
                Text("Total Assets")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                if totalsByCurrency.count > 2 {
                    TabView {
                        ForEach(totalsByCurrency, id: \.code) { item in
                            currencyText(item.total, code: item.code)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 22)
                } else {
                    VStack(spacing: 1) {
                        ForEach(totalsByCurrency, id: \.code) { item in
                            currencyText(item.total, code: item.code)
                        }
                    }
                }
            }
            .frame(maxWidth: 110)
            .padding(.horizontal, 4)
        }
        .padding()
        .background(.background.secondary)
    }

    private func currencyText(_ amount: Decimal, code: String) -> some View {
        Text(amount, format: .currency(code: code))
            .font(.system(size: totalsByCurrency.count > 1 ? 14 : 18, weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.3)
            .allowsTightening(true)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    NavigationStack {
        AccountsView()
            .modelContainer(ModelContainerFactory.inMemoryPreview)
            .environmentObject(SettingsViewModel())
    }
}
