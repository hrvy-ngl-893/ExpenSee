//
//  QuickLogWidget.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct QuickLogProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickLogEntry {
        QuickLogEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> Void) {
        completion(QuickLogEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> Void) {
        let entry = QuickLogEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct QuickLogEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget View
struct QuickLogWidgetView: View {
    var entry: QuickLogEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            Link(destination: URL(string: "expen-see://add-expense")!) {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "plus")
                        .font(.title2.bold())
                }
            }
        case .accessoryRectangular:
            Link(destination: URL(string: "expen-see://add-expense")!) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("ExpenSee")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Log Expense")
                            .font(.footnote.bold())
                    }
                }
            }
        default:
            Link(destination: URL(string: "expen-see://add-expense")!) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.tint.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.tint)
                    }
                    
                    VStack(spacing: 2) {
                        Text("Log Expense")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Tap to add entry")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Widget Definition
struct QuickLogWidget: Widget {
    let kind: String = "QuickLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: QuickLogProvider()
        ) { entry in
            QuickLogWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Log Expense")
        .description("One-tap shortcut to immediately log a spending entry.")
        #if os(iOS)
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
        #endif
    }
}

// MARK: - Previews
#Preview("Small Home Screen", as: .systemSmall) {
    QuickLogWidget()
} timeline: {
    QuickLogEntry(date: .now)
}

#if os(iOS)
#Preview("Lock Screen Circular", as: .accessoryCircular) {
    QuickLogWidget()
} timeline: {
    QuickLogEntry(date: .now)
}
#endif
