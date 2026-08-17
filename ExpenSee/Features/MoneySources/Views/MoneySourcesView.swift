//
//  MoneySourcesView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

public struct MoneySourcesView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel

    @Query(sort: \MoneySource.name) private var sources: [MoneySource]

    private let viewModel = MoneySourcesViewModel()

    @State private var activeSheet: FormRoute?

    private enum FormRoute: Identifiable {
        case add
        case edit(MoneySource)

        var id: String {
            switch self {
            case .add:
                return "add"
            case .edit(let source):
                return source.id.uuidString
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // MARK: - Chart Header
                Section {
                    MoneySourcesChartView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // MARK: - Money Sources List
                Section {
                    ForEach(sources) { source in
                        sourceRow(source)
                    }
                    .onDelete(perform: deleteSources)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Money Sources")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { activeSheet = .add }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { route in
                switch route {
                case .add:
                    MoneySourceFormView()
                        .presentationDetents([.medium, .large])
                case .edit(let source):
                    MoneySourceFormView(sourceToEdit: source)
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }

    // MARK: - Components

    private func sourceRow(_ source: MoneySource) -> some View {
        HStack(spacing: 12) {
            Image(systemName: source.displayIcon)
                .font(.title2)
                .foregroundStyle(source.displayColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text(source.balance, format: .currency(code: settings.currencyCode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            activeSheet = .edit(source)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                activeSheet = .edit(source)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button {
                activeSheet = .edit(source)
            } label: {
                Label("Edit Source", systemImage: "pencil")
            }
        }
    }

    // MARK: - Data Actions

    private func deleteSources(at offsets: IndexSet) {
        for index in offsets {
            viewModel.delete(sources[index], from: context)
        }
    }
}

#Preview {
    MoneySourcesView()
        .modelContainer(ModelContainerFactory.shared)
        .environmentObject(SettingsViewModel())
}
