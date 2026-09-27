import SwiftUI

struct MealSetPanel: View {
    @Binding var entry: MealSetEntry
    var onChange: () -> Void
    var onBack: () -> Void

    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: 12) {
            // 顶部：返回 + 标题 + kcal
            HStack(spacing: 10) {
                Button { onBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(.white.opacity(0.18)))
                }
                .buttonStyle(.plain)

                Text(entry.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Spacer()

                Text("kcal_with_unit \(Int64(entry.kcal.rounded()))")
                    .font(.headline).bold().monospacedDigit()
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(.horizontal, 14)

            // 内容块
            ScrollView {
                VStack(spacing: 12) {
                    // 明细（复用 FoodPortionRow；套餐内不提供删除按钮）
                    VStack(spacing: 0) {
                        ForEach($entry.items) { $p in
                            FoodPortionRow(
                                item: $p,
                                onDelete: { /* 套餐内不删除；如需可放开 */ },
                                onChanged: { onChange() }
                            )
                            if p.id != entry.items.last?.id {
                                Divider().padding(.leading, 12)
                            }
                        }
                    }
                    .padding(ContentBlockStyle.padding)
                    .background(
                        RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius)
                            .fill(.thinMaterial)
                    )

                    // 添加（仅单品）
                    Button {
                        showingPicker = true
                    } label: {
                        Label(LocalizedStringKey("add_from_food_library"), systemImage: "plus.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(ContentBlockStyle.padding)
                    .background(
                        RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius)
                            .fill(.thinMaterial)
                    )
                }
                .padding(14)
            }
        }
        // 仅单品选择；不支持嵌套套餐
        .sheet(isPresented: $showingPicker) {
            FoodPicker(
                mode: .templatesOnly,
                onSelectTemplate: { food in
                    let q: Double = (food.unit == .perPiece) ? 1 : 100
                    let portion = FoodPortion(template: food, defaultQuantity: q)
                    entry.items.append(portion)
                    onChange()
                },
                onSelectMealSet: { _ in /* 不嵌套套餐 */ }
            )
        }
    }
}
