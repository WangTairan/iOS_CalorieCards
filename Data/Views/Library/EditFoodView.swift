// UI/Library/EditFoodView.swift
import SwiftUI
import SwiftData

struct EditFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allFoods: [FoodTemplate]

    @Bindable var food: FoodTemplate
    @State private var name: String
    @State private var unit: UnitKind
    @State private var kcalPerUnit: Double
    @State private var errorMessage: String?

    init(food: FoodTemplate) {
        _food = Bindable(food)
        // 初始化为“当前语言”名
        let isZH = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        _name = State(initialValue: isZH ? food.nameZH : food.nameEN)
        _unit = State(initialValue: food.unit)
        _kcalPerUnit = State(initialValue: food.kcalPerUnit)
    }

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
            .navigationTitle(String(localized: "edit"))
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

        let isZH = Locale.preferredLanguages.first?.hasPrefix("zh") == true

        // 基于“当前语言显示名”查重（忽略自己）
        let exists = allFoods.contains {
            guard $0 != food else { return false }
            return ($0.localizedName == trimmed)
        }
        guard !exists else {
            errorMessage = String(localized: "food_name_exists")
            return
        }

        // 只改当前语言字段
        if isZH {
            food.nameZH = trimmed
        } else {
            food.nameEN = trimmed
        }
        food.unit = unit
        food.kcalPerUnit = kcalPerUnit

        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = String(localized: "save_failed")
            print("EditFood save error:", error)
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
