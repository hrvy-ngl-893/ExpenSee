//
//  MoneySourcesChartView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import Charts
import SwiftData
import ExpenSeeCore

public struct MoneySourcesChartView: View {
    @EnvironmentObject private var settings: SettingsViewModel

    @Query(sort: \MoneySource.name) private var sources: [MoneySource]

    public init() {}

    private var totalBalance: Decimal {
        sources.reduce(0) { $0 + $1.balance }
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
            VStack(spacing: 4) {
                Text("Total Assets")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(totalBalance, format: .currency(code: settings.currencyCode))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .padding(.horizontal, 24)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }
}

#Preview {
    NavigationStack {
        MoneySourcesView()
            .modelContainer(ModelContainerFactory.shared)
            .environmentObject(SettingsViewModel())
    }
}
