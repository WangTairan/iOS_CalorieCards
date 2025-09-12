import SwiftUI

struct CardView: View {
    let card: MealCard
    var isEditing: Bool = false
    var onDelete:   (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil
    var onMoveRight:(() -> Void)? = nil

    private let cornerIconSide: CGFloat = 28
    private let cornerIconFontSize: CGFloat = 14
    private let contentPadding: CGFloat = 14

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 18)
                .fill(card.displayColor)
                .shadow(radius: 1, y: 1)

            VStack(alignment: .leading, spacing: 6) {
                // 顶部标题区
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.2))
                        Image(systemName: card.displaySymbol)
                            .font(.system(size: cornerIconFontSize, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: cornerIconSide, height: cornerIconSide)

                    Text(card.name.title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()
                }

                Spacer()

                // 底部：kcal + pcf
                VStack(alignment: .leading, spacing: 2) {
                    Text("kcal_with_unit \(Int64(card.kcal))")
                        .font(.system(size: 28, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    // ⬇️ 新增：三大营养素一行
                    HStack(spacing: 12) {
                        macroText(prefix: "P", value: Double(card.protein))
                        macroText(prefix: "C", value: Double(card.carb))
                        macroText(prefix: "F", value: Double(card.fat))
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(contentPadding)

            if isEditing {
                VStack(spacing: 8) {
                    Button { onDelete?() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2))
                            Image(systemName: "trash")
                                .font(.system(size: cornerIconFontSize, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                        .frame(width: cornerIconSide, height: cornerIconSide)
                    }
                    .buttonStyle(.plain)

                    Button { onSettings?() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2))
                            Image(systemName: "gearshape")
                                .font(.system(size: cornerIconFontSize, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: cornerIconSide, height: cornerIconSide)
                    }
                    .buttonStyle(.plain)

                    Button { onMoveRight?() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2))
                            Image(systemName: "arrow.right")
                                .font(.system(size: cornerIconFontSize, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: cornerIconSide, height: cornerIconSide)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, contentPadding)
                .padding(.trailing, contentPadding)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Helper
    private func macroText(prefix: String, value: Double) -> some View {
        HStack(spacing: 2) {
            Text(prefix)
            Text(fmt(value)).monospacedDigit()
            Text(String(localized: "g_unit"))
        }
    }

    private func fmt(_ x: Double) -> String {
        let v = (x * 10).rounded() / 10
        if abs(v.rounded() - v) < 0.0001 { return String(Int(v)) }
        return String(format: "%.1f", v)
    }
}
