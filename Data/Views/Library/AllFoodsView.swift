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

    // 基于“当前语言名”进行过滤与排序
    private var displayedFoods: [FoodTemplate] {
        let base = foods.sorted {
            $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending
        }
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
                    ForEach(pinned) {
                        RowFood(food: $0, onEdit: { editingFood = $0 })
                            .listRowSeparator(.visible)
                    }
                }
            }

            Section(String(localized: "all_foods")) {
                ForEach(others) {
                    RowFood(food: $0, onEdit: { editingFood = $0 })
                        .listRowSeparator(.visible)
                }
            }
        }
        .listStyle(.insetGrouped)                 // 透明背景风格
        .scrollContentBackground(.hidden)         // 去掉默认灰底
        .navigationTitle(String(localized: "food_library"))
        .navigationBarTitleDisplayMode(.inline)   // 标题 inline
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "search")
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Text(String(localized: "add_food"))
                }
            }
        }
        .sheet(isPresented: $showingAdd) { AddFoodView() }
        .sheet(item: $editingFood) { food in
            EditFoodView(food: food)
        }
    }
}

// 行视图：编辑/删除保留；新增“置顶/取消置顶”按钮（行内）
private struct RowFood: View {
    @Environment(\.modelContext) private var context
    @Bindable var food: FoodTemplate
    var onEdit: (FoodTemplate) -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.localizedName).bold()
                Text(food.unitLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            // 右侧：kcal + pin按钮
            HStack(spacing: 10) {
                Text("\(Int(food.kcalPerUnit)) \(String(localized: "kcal_unit"))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Button {
                    food.isPinned.toggle()
                    try? context.save()
                } label: {
                    Image(systemName: food.isPinned ? "pin.fill" : "pin")
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
                .foregroundStyle(food.isPinned ? .orange : .secondary)
                .accessibilityLabel(
                    Text(food.isPinned ? String(localized: "unpin") : String(localized: "pin"))
                )
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

