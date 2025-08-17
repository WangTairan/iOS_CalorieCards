import SwiftUI

struct FoodQuantityEditor: View {
    let template: FoodTemplate
    var onConfirm: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("数量 (\(unitLabel(template)))")) {
                    HStack {
                        Button("-") {
                            stepQuantity(-1)
                        }
                        .buttonStyle(.bordered)

                        TextField("数量", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)

                        Button("+") {
                            stepQuantity(1)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Section(header: Text("热量")) {
                    Text("\(calculatedKcal, specifier: "%.0f") 千卡")
                        .font(.title2)
                        .bold()
                }
            }
            .navigationTitle(localizedName(template))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        onConfirm(calculatedKcal)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                quantity = defaultQuantity()
            }
        }
    }

    private var calculatedKcal: Double {
        switch template.unit {
        case .per100g, .per100ml:
            return template.kcalPerUnit * quantity / 100
        case .perPiece:
            return template.kcalPerUnit * quantity
        }
    }

    private func stepQuantity(_ dir: Int) {
        switch template.unit {
        case .per100g, .per100ml:
            quantity = max(0, quantity + Double(dir) * 50)
        case .perPiece:
            quantity = max(0, quantity + Double(dir) * 1)
        }
    }

    private func defaultQuantity() -> Double {
        switch template.unit {
        case .per100g, .per100ml: return 100
        case .perPiece:           return 1
        }
    }

    func localizedName(_ f: FoodTemplate) -> String {
        Locale.current.language.languageCode?.identifier == "zh" ? f.nameZH : f.nameEN
    }

    func unitLabel(_ f: FoodTemplate) -> String {
        switch f.unit {
        case .per100g:  return "克"
        case .per100ml: return "毫升"
        case .perPiece: return "个"
        }
    }
}
