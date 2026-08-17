//
//  SourcePickerView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct SourcePickerView: View {
    @Query(sort: \MoneySource.name) private var sources: [MoneySource]
    @Binding var selectedSource: MoneySource?

    var body: some View {
        Picker("Source", selection: $selectedSource) {
            Text("None")
                .tag(nil as MoneySource?)

            Divider()

            ForEach(sources) { source in
                Label(source.name, systemImage: "wallet.bifold")
                    .tag(source as MoneySource?)
            }
        }
        .pickerStyle(.menu)
    }
}
