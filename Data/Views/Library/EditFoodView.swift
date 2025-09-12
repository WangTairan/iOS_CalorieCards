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

    @State private var proteinPerUnit: Double
    @State private var carbPerUnit: Double
    @State private var fatPerUnit: Double

    @State private var errorMessage: String?

    init(food: FoodTemplate) {
        _food = Bindable(food)
        let isZH = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        _name = State(initialValue: isZH ? food.nameZH : food.nameEN)
        _unit = State(initialValue: food.unit)
        _kcalPerUnit = State(initialValue: food.kcalPerUnit)
        _proteinPerUnit = State(initialValue: food.proteinPerUnit)
        _carbPerUnit    = State(initialValue: food.carbPerUnit)
        _fatPerUnit     = State(initialValue: food.fatPerUnit)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "food_name"), text: $name)

                    Picker(String(localized: "unit"), selection: $unit) {
                        ForEach(UnitKind.allCases, id: \.self) {
                            Text(unitLocalized($0))
                        }
                    }

                    // kcal 统一布局：单位放后
                    HStack {
                        Text(String(localized: "kcal_per_unit"))
                        Spacer()
                        TextField("0", value: $kcalPerUnit, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(String(localized: "kcal_unit")).foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(String(localized: "protein_per_unit"))
                        Spacer()
                        TextField("0", value: $proteinPerUnit, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(String(localized: "g_unit")).foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(String(localized: "carb_per_unit"))
                        Spacer()
                        TextField("0", value: $carbPerUnit, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(String(localized: "g_unit")).foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(String(localized: "fat_per_unit"))
                        Spacer()
                        TextField("0", value: $fatPerUnit, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(String(localized: "g_unit")).foregroundStyle(.secondary)
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
        let exists = allFoods.contains {
            guard $0 != food else { return false }
            return ($0.localizedName == trimmed)
        }
        guard !exists else {
            errorMessage = String(localized: "food_name_exists")
            return
        }

        if isZH { food.nameZH = trimmed } else { food.nameEN = trimmed }
        food.unit = unit
        food.kcalPerUnit = kcalPerUnit
        food.proteinPerUnit = proteinPerUnit
        food.carbPerUnit = carbPerUnit
        food.fatPerUnit = fatPerUnit

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
