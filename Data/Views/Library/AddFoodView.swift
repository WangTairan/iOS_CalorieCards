// UI/Library/AddFoodView.swift
import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allFoods: [FoodTemplate]

    @State private var name = ""
    @State private var unit: UnitKind = .per100g
    @State private var kcalPerUnit: Double = 100
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "food_name"), text: $name)
                    Picker(String(localized: "unit"), selection: $unit) {
                        ForEach(UnitKind.allCases, id: \.self) { Text(unitLocalized($0)) }
                    }
                    HStack {
                        Text(String(localized: "kcal_per_unit"))
                        Spacer()
                        TextField("0", value: $kcalPerUnit, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                if let msg = errorMessage {
                    Text(msg).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle(String(localized: "add_food"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "save")) { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 基于“当前语言显示名”查重
        let exists = allFoods.contains { $0.localizedName == trimmed }
        guard !exists else {
            errorMessage = String(localized: "food_name_exists")
            return
        }

        // 新建：两个语言名都设为用户输入
        let f = FoodTemplate(nameZH: trimmed, nameEN: trimmed, unit: unit, kcalPerUnit: kcalPerUnit)
        context.insert(f)
        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = String(localized: "save_failed_try_again")
            print("AddFood save error:", error)
        }
    }
}

private func unitLocalized(_ unit: UnitKind) -> String {
    switch unit {
    case .per100g:  return String(localized: "per_100g")
    case .per100ml: return String(localized: "per_100ml")
    case .perPiece: return String(localized: "per_piece")
    }
}
