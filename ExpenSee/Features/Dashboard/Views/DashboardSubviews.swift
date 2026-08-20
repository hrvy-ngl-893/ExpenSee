//
//  DashboardSubviews.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/19/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

// MARK: - Picker Component
struct SpendingLimitPickerView: View {
    let limits: [SpendingLimit]
    let featuredID: PersistentIdentifier?
    @Binding var selectedIDString: String

    // Local sorted state to handle dynamic reordering
    @State private var orderedLimits: [SpendingLimit] = []

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(orderedLimits, id: \.persistentModelID) { spendingLimit in
                    let isSelected = featuredID == spendingLimit.persistentModelID
                    
                    Button {
                        selectAndReorder(spendingLimit)
                    } label: {
                        HStack(spacing: 6) {
                            if spendingLimit.categories.count > 1 {
                                Image(systemName: "tag.fill")
                            } else if let category = spendingLimit.categories.first {
                                Image(systemName: category.iconString)
                            }
                            
                            Text(spendingLimit.name)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.accentColor : Color.gray.opacity(0.15), in: Capsule())
                        .foregroundStyle(isSelected ? .white : .primary)
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: orderedLimits)
        }
        .onAppear {
            orderedLimits = limits
            moveToFrontIfNeeded()
        }
        .onChange(of: featuredID) { _, _ in
            moveToFrontIfNeeded()
        }
    }

    private func selectAndReorder(_ limit: SpendingLimit) {
        selectedIDString = String(describing: limit.persistentModelID)
        reorder(selectedLimit: limit)
    }

    private func moveToFrontIfNeeded() {
        if let featured = orderedLimits.first(where: { $0.persistentModelID == featuredID }) {
            reorder(selectedLimit: featured)
        }
    }

    private func reorder(selectedLimit: SpendingLimit) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            var updated = orderedLimits
            if let index = updated.firstIndex(where: { $0.persistentModelID == selectedLimit.persistentModelID }) {
                let item = updated.remove(at: index)
                updated.insert(item, at: 0) // Shift selected item to index 0
                orderedLimits = updated
            }
        }
    }
}

// MARK: - Animatable Ring Shape
struct RingShape: Shape {
    var progress: Double

    // Tells SwiftUI how to interpolate values during animation frames
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clamped = min(max(progress, 0.0), 1.0)
        
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + (clamped * 360)),
            clockwise: false
        )
        return path
    }
}

// MARK: - Hero Gauge Card Component
struct HeroSpendingLimitCard: View {
    let spendingLimit: SpendingLimit
    let remaining: Decimal
    let ratio: Double
    let statusColor: Color

    private let strokeWidth: CGFloat = 16

    var body: some View {
        VStack {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: strokeWidth)

                // Animated Progress Fill Shape
                RingShape(progress: ratio)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    .animation(.spring(response: 0.6, dampingFraction: 0.75), value: ratio)

                // Inner Content Container
                VStack(spacing: 4) {
                    Text(spendingLimit.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2) // Keeps multi-line titles clean without vertical clipping
                        .minimumScaleFactor(0.8)

                    Text(remaining, format: .currency(code: spendingLimit.currencyCode))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(remaining >= 0 ? .primary : Color.red)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    Text(remaining < 0 ? "Over Budget" : "\(Int(min(max(ratio, 0), 1) * 100))% remaining")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)
                        .lineLimit(1)
                }
                .padding(.horizontal, strokeWidth + 16)
            }
            .frame(width: 240, height: 240)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Empty State Component
struct EmptyBudgetHeroView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            
            Text("No Active Budgets")
                .font(.headline)
            
            Text("Set a daily, weekly, monthly, or category budget to track spend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Unified Budget Card Component
struct UnifiedBudgetCard: View {
    let spendingLimit: SpendingLimit
    let spent: Decimal
    let remaining: Decimal

    private var progressRatio: Double {
        guard spendingLimit.limitAmount > 0 else { return 0 }
        let spentDouble = NSDecimalNumber(decimal: spent).doubleValue
        let limitDouble = NSDecimalNumber(decimal: spendingLimit.limitAmount).doubleValue
        return min(max(spentDouble / limitDouble, 0.0), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Category Icon & Name
            HStack(spacing: 6) {
                if spendingLimit.categories.count > 1 {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                } else if let category = spendingLimit.categories.first {
                    Image(systemName: category.iconString)
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }

                Text(spendingLimit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            // Middle Row: Spent / Limit Values
            VStack(alignment: .leading, spacing: 2) {
                Text(spent, format: .currency(code: spendingLimit.currencyCode))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("of \(spendingLimit.limitAmount.formatted(.currency(code: spendingLimit.currencyCode)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Bottom Row: Linear Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))

                    Capsule()
                        .fill(remaining >= 0 ? Color.accentColor : Color.red)
                        .frame(width: geo.size.width * CGFloat(progressRatio))
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, maxHeight: 110) // Guarantees identical tile sizes
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .modelContainer(ModelContainerFactory.inMemoryPreview)
            .environmentObject(SettingsViewModel())
    }
}
