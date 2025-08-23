import SwiftUI

struct CardView: View {
    let card: MealCard
    var isEditing: Bool = false
    var onDelete:   (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil
    var onMoveRight:(() -> Void)? = nil   // ✅ 新增：向右移动

    // 基准：左上角小图标的视觉尺寸
    private let cornerIconSide: CGFloat = 28
    private let cornerIconFontSize: CGFloat = 14
    private let contentPadding: CGFloat = 14

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 背板
            RoundedRectangle(cornerRadius: 18)
                .fill(card.displayColor)
                .shadow(radius: 1, y: 1)

            // 内容（左上角小图标 + 标题 + kcal）
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    // 左上角小图标（参考基准）
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
                Text("kcal_with_unit \(Int64(card.kcal))")
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .padding(contentPadding)

            // 编辑态：右上角“纵向三颗”小圆按钮
            if isEditing {
                VStack(spacing: 8) {
                    // 删除（红色）
                    Button { onDelete?() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2))
                            Image(systemName: "trash")
                                .font(.system(size: cornerIconFontSize, weight: .semibold))
                                .foregroundStyle(.red)
                                .symbolRenderingMode(.monochrome)
                        }
                        .frame(width: cornerIconSide, height: cornerIconSide)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(String(localized: "delete_card")))

                    // 设置（白色）
                    Button { onSettings?() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2))
                            Image(systemName: "gearshape")
                                .font(.system(size: cornerIconFontSize, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolRenderingMode(.monochrome)
                        }
                        .frame(width: cornerIconSide, height: cornerIconSide)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(String(localized: "edit_card_settings")))

                    // ✅ 向右移动（白色）——第三个
                    Button { onMoveRight?() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2))
                            Image(systemName: "arrow.right")
                                .font(.system(size: cornerIconFontSize, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolRenderingMode(.monochrome)
                        }
                        .frame(width: cornerIconSide, height: cornerIconSide)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(String(localized: "move_card_right")))
                }
                .padding(.top, contentPadding)      // 与内容区 padding 对齐
                .padding(.trailing, contentPadding) // 右上角定位
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}
