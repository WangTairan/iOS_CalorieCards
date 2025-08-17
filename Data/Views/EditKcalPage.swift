import SwiftUI

struct EditKcalPage: View {
    @Environment(\.dismiss) private var dismiss
    let mealTitle: String
    let color: Color
    let initial: Int
    var onSave: (Int) -> Void

    @State private var kcalText: String = ""
    @State private var showingPicker = false

    @State private var selectedFood: FoodTemplate? = nil
    @State private var quantity: Double = 0

    var body: some View {
        Form {
            // 卡片风格大标题（延续卡片视觉）
            Section {
                HStack(spacing: 10) {
                    Circle().fill(color.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "flame.fill")
                                .font(.footnote)
                                .foregroundStyle(color)
                        )
                    Text(mealTitle).font(.title2).bold()
                }
            }

            if let food = selectedFood {
                Section {
                    Text("\(localizedName(food)) · \(unitShort(food))")
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            stepQuantity(food, down: true)
                        } label: {
                            Image(systemName: "minus.circle.fill").font(.title2)
                        }

                        Spacer()

                        TextField("", value: $quantity, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 80)

                        Text(unitShort(food))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            stepQuantity(food, down: false)
                        } label: {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                    }

                    HStack {
                        Text("计算热量")
                        Spacer()
                        Text("\(Int(calculatedKcal(food).rounded())) kcal")
                            .bold()
                            .monospacedDigit()
                    }
                }
            }

            Section {
                Button {
                    showingPicker = true
                } label: {
                    Label("从食材库选择", systemImage: "magnifyingglass")
                }
            }

            Section {
                HStack {
                    Text("或直接输入热量").foregroundStyle(.secondary)
                    Spacer()
                    TextField("0", text: $kcalText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("kcal").foregroundStyle(.secondary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline) // 保持紧凑，主标题交给上面的“卡片区”
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    if let food = selectedFood {
                        onSave(Int(calculatedKcal(food).rounded()))
                    } else {
                        let v = Int(kcalText) ?? 0
                        onSave(max(0, v))
                    }
                    dismiss()
                }
                .disabled((selectedFood == nil) && Int(kcalText) == nil)
            }
        }
        .onAppear { kcalText = String(initial) }
        .sheet(isPresented: $showingPicker) {
            FoodPicker { food in
                selectedFood = food
                switch food.unit {
                case .per100g, .per100ml: quantity = 100
                case .perPiece:           quantity = 1
                }
            }
        }
    }

    // MARK: - Helpers（原封不动）
    func stepQuantity(_ food: FoodTemplate, down: Bool) {
        let step: Double = (food.unit == .perPiece) ? 1 : 50
        quantity = max(0, quantity + (down ? -step : step))
    }
    func calculatedKcal(_ food: FoodTemplate) -> Double {
        switch food.unit {
        case .per100g, .per100ml: return food.kcalPerUnit * quantity / 100.0
        case .perPiece:           return food.kcalPerUnit * quantity
        }
    }
    func localizedName(_ f: FoodTemplate) -> String {
        Locale.current.language.languageCode?.identifier == "zh" ? f.nameZH : f.nameEN
    }
    func unitShort(_ f: FoodTemplate) -> String {
        switch f.unit {
        case .per100g:  return "g"
        case .per100ml: return "ml"
        case .perPiece: return "个"
        }
    }
}
