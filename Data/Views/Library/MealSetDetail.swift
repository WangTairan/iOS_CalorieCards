// Views/MealSetDetail.swift
import SwiftUI
import SwiftData
import Foundation

struct MealSetDetail: View {
    @Environment(\.modelContext) private var context
    @Bindable var set: MealSet

    var body: some View {
        List {
            ForEach(set.items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.template.localizedName).bold()
                        Text(item.template.unitLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("× \(Int(item.defaultQuantity))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { set.items.remove(at: $0) }
                try? context.save()
            }
        }
        .navigationTitle(set.name)
    }
}
