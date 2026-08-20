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
    
    // Actions passed from parent View
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            categoryIcon
            VStack(alignment: .leading) {
                HStack {
                    Text(transaction.note.isEmpty ? "Expense" : transaction.note)
                        .font(.body)
                        .fontWeight(.medium)
                    Spacer()
                    Text(transaction.amount, format: .currency(code: currencyCode))
                        .font(.callout)
                        .fontWeight(.bold)
                    
                }
                
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text(transaction.timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    Text("•")
                    Text(transaction.account?.name ?? "")
                }
                .frame(alignment: .leading)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
        }
        
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit?()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label("Edit Expense", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete Expense", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var categoryIcon: some View {
        if let category = transaction.category {
            Image(systemName: category.iconString)
                .font(.title2)
                .foregroundStyle(Color(hex: category.hexColor) ?? .accentColor)
        } else {
            Image(systemName: "cart.fill")
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())
        }
    }
}
