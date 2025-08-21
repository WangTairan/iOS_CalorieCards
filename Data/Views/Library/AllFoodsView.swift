// UI/Library/AllFoodsView.swift
import SwiftUI
import SwiftData

struct AllFoodsView: View {
    @Environment(\.modelContext) private var context
    @Query private var foods: [FoodTemplate]

    @State private var query = ""
    @State private var showingAdd = false
    @State private var editingFood: FoodTemplate? = nil

    init() {
        _foods = Query(sort: [SortDescriptor(\FoodTemplate.nameEN, order: .forward)])
    }

    private var displayedFoods: [FoodTemplate] {
        let base = foods.sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
        guard !query.isEmpty else { return base }
        let q = query.lowercased()
        return base.filter { $0.localizedName.lowercased().contains(q) }
    }

    var body: some View {
        List {
            let pinned = displayedFoods.filter { $0.isPinned }
            let others = displayedFoods.filter { !$0.isPinned }

            if !pinned.isEmpty {
                Section(String(localized: "pinned")) {
                    ForEach(pinned) { RowFood(food: $0, onEdit: { editingFood = $0 }) }
                }
            }

            Section(String(localized: "all_foods")) {
                ForEach(others) { RowFood(food: $0, onEdit: { editingFood = $0 }) }
            }
        }
        .navigationTitle(String(localized: "food_library"))
        .navigationBarTitleDisplayMode(.inline)   // ← 标题改为 inline
        .searchable(text: $query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: String(localized: "search"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text(String(localized: "add_food"))
                    }
                }
            }
        }

        .sheet(isPresented: $showingAdd) { AddFoodView() }
        .sheet(item: $editingFood) { food in
            EditFoodView(food: food)
        }
    }
}

// 行视图（已移除“置顶/取消置顶”的左划操作；仅保留编辑/删除）
private struct RowFood: View {
    @Environment(\.modelContext) private var context
    @Bindable var food: FoodTemplate
    var onEdit: (FoodTemplate) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.localizedName).bold()
                Text(food.unitLabel).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(food.kcalPerUnit)) \(String(localized: "kcal_unit"))")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            // 仅显示“已置顶”标识，不提供滑动置顶
            if food.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(String(localized: "edit")) {
                onEdit(food)
            }
            .tint(.blue)

            Button(role: .destructive) {
                context.delete(food)
                try? context.save()
            } label: {
                Text(String(localized: "delete"))
            }
        }
    }
}
