import SwiftUI
import SwiftData

private enum MacroCol {
    static let width: CGFloat = 40  // 固定列宽；可按需要调节
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

                Text("\(Int(food.kcalPerUnit)) kcal")
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

            // 第二行：单位 + P/C/F
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(food.unitLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Grid(alignment: .trailing, horizontalSpacing: 8) {
                    GridRow {
                        macroCol(prefix: "protein", value: food.proteinPerUnit)
                        macroCol(prefix: "carb", value: food.carbPerUnit)
                        macroCol(prefix: "fat", value: food.fatPerUnit)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func macroCol(prefix: String, value: Double) -> some View {
        HStack(spacing: 2) {
            Text(prefix)
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
