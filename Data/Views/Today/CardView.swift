import SwiftUI

struct CardView: View {
    let card: MealCard
    var isEditing: Bool = false
    var onDelete: (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil

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

            // 编辑态：右上角纵向按钮，与左上角图标完全同尺寸 & 同上边距
            if isEditing {
                VStack(spacing: 8) {
                    // 删除（红色，顶上）——与左上角完全相同的两层结构
                    Button {
                        onDelete?()
                    } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2)) // 外圈同样的浅白圆
                            Image(systemName: "trash")               // 纯符号，不要 *.circle.fill 变体
                                .font(.system(size: 14, weight: .semibold)) // 和左上角一致
                                .foregroundStyle(.red)                       // 只改颜色为红色
                                .symbolRenderingMode(.monochrome)
                        }
                        .frame(width: 28, height: 28)               // 和左上角一致
                    }
                    .buttonStyle(.plain)

                    // 设置（白色，在下）——同结构
                    Button {
                        onSettings?()
                    } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2))
                            Image(systemName: "gearshape")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolRenderingMode(.monochrome)
                        }
                        .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 14)       // 和内容区 padding 对齐
                .padding(.trailing, 14)  // 右上角定位
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}
