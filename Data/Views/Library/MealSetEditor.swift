// Views/MealSetEditor.swift
import SwiftUI
import SwiftData

struct MealSetEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \FoodTemplate.nameEN) private var templates: [FoodTemplate]

    @State private var name: String = ""
    @State private var selectedTemplates: [FoodTemplate: Double] = [:] // quantity

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "set_name")) {
                    TextField(String(localized: "enter_name"), text: $name)
                }

                Section(String(localized: "choose_foods")) {
                    ForEach(templates.sortedByLocalizedName()) { t in
                        QuantityRow(
                            title: t.localizedName,
                            quantity: Binding(
                                get: { selectedTemplates[t] ?? 0 },
                                set: { newVal in
                                    if newVal > 0 {
                                        selectedTemplates[t] = newVal
                                    } else {
                                        selectedTemplates.removeValue(forKey: t)
                                    }
                                }
                            )
                        )
                    }
                }
            }
            .navigationTitle(String(localized: "new_meal_set"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedTemplates.isEmpty
    }

    private func save() {
        let items = selectedTemplates.compactMap { (t, q) -> MealSetItem? in
            q > 0 ? MealSetItem(template: t, defaultQuantity: q) : nil
        }
        let set = MealSet(name: name.trimmingCharacters(in: .whitespaces), items: items)
        context.insert(set)
        try? context.save()
        dismiss()
    }
}

private struct QuantityRow: View {
    let title: String
    @Binding var quantity: Double

    var body: some View {
        HStack {
            Text(title).bold()
            Spacer()
            Stepper(value: $quantity, in: 0...99_999, step: 1) {
                Text(quantity > 0 ? "\(Int(quantity))" : String(localized: "add"))
                    .frame(width: 64, alignment: .trailing)
            }
        }
    }
}

// MARK: - Helpers
private extension Array where Element == FoodTemplate {
    func sortedByLocalizedName() -> [FoodTemplate] {
        sorted {
            $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending
        }
    }
}
