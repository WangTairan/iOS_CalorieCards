import SwiftUI
import SwiftData

private enum MacroCol {
    static let width: CGFloat = 60  // 可按需要调整
}

struct LibraryRowTemplate: View {
    @Environment(\.modelContext) private var context
    @Bindable var food: FoodTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 第一行：名字 + 热量 + pin
            HStack(spacing: 6) {
                Text(food.localizedName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Text("kcal_with_unit \(Int64(food.kcalPerUnit))")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Button {
                    food.isPinned.toggle()
                    try? context.save()
                } label: {
                    Image(systemName: food.isPinned ? "pin.fill" : "pin")
                        .foregroundStyle(food.isPinned ? .orange : .secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 6)
            }

            // 第二行：单位 + 本地化的 P/C/F
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(food.unitLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Grid(alignment: .trailing, horizontalSpacing: 8) {
                    GridRow {
                        macroCol(labelKey: "macro_p", value: food.proteinPerUnit) // ✅ 本地化
                        macroCol(labelKey: "macro_c", value: food.carbPerUnit)    // ✅ 本地化
                        macroCol(labelKey: "macro_f", value: food.fatPerUnit)     // ✅ 本地化
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // 固定列宽 + 右对齐 + 等宽数字；label 使用本地化 key
    @ViewBuilder
    private func macroCol(labelKey: String, value: Double) -> some View {
        HStack(spacing: 2) {
            Text(LocalizedStringKey(labelKey))     // "macro_p" / "macro_c" / "macro_f"
            Text(fmt(value)).monospacedDigit()
            Text(String(localized: "g_unit"))
        }
        .frame(width: MacroCol.width, alignment: .trailing)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}

private func fmt(_ x: Double) -> String {
    let v = (x * 10).rounded() / 10
    if abs(v.rounded() - v) < 0.0001 { return String(Int(v)) }
    return String(format: "%.1f", v)
}
