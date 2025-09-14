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

                // 底部：PCF 三行 + kcal
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        macroRow(labelKey: "macro_p", value: Double(card.protein))
                        macroRow(labelKey: "macro_c", value: Double(card.carb))
                        macroRow(labelKey: "macro_f", value: Double(card.fat))
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.92))

                    Text("kcal_with_unit \(Int64(card.kcal))")
                        .font(.system(size: 28, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.top, 2)
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

    // MARK: - Helpers
    private func macroRow(labelKey: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Text(LocalizedStringKey(labelKey))
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
