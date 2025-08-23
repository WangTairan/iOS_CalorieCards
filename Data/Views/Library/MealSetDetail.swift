import SwiftUI
import SwiftData

struct MealSetDetail: View {
    @Environment(\.modelContext) private var context
    @Bindable var set: MealSet

    @State private var showingEdit = false

    // 列宽配置
    private let qtyColWidth: CGFloat = 72
    private let unitColWidth: CGFloat = 42

    var body: some View {
        List {
            Section(String(localized: "foods")) {
                ForEach(set.items) { portion in
                    row(for: portion)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)        // ✅ 去掉默认背景
        .background(Color.clear)                 // ✅ 透明背景
        .navigationTitle(set.name)
        .navigationBarTitleDisplayMode(.inline)   // 👈 标题 inline
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.circle")
                        Text(String(localized: "edit"))
                    }
                    .padding(.horizontal, 2)
                }
                .controlSize(.regular)
            }
        }
        .sheet(isPresented: $showingEdit) {
            MealSetEditor(existingSet: set)
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for item: MealSetItem) -> some View {
        let portion = FoodPortion(item: item)

        HStack {
            // 左侧：只显示名称
            VStack(alignment: .leading, spacing: 4) {
                Text(item.template.localizedName)
                    .font(.subheadline)
                    .bold()
            }

            Spacer()

            // 右侧：数字 + 单位（定宽对齐）
            HStack(spacing: 4) {
                Text(qtyText(from: portion))
                    .font(.headline)
                    .monospacedDigit()
                    .frame(width: qtyColWidth, alignment: .trailing)
                    .foregroundStyle(.secondary)

                Text(unitText(from: portion))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: unitColWidth, alignment: .leading)
            }
        }
        .listRowSeparator(.visible)   // 保留分隔线风格
    }

    // MARK: - Helpers

    private func qtyText(from portion: FoodPortion?) -> String {
        guard let p = portion else { return "0" }
        return "\(Int(p.quantity.rounded()))"
    }

    private func unitText(from portion: FoodPortion?) -> String {
        guard let p = portion else { return "" }
        return p.unitShortLocalized   // 动态单位
    }
}
