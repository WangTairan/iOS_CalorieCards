import SwiftUI
import SwiftData
import Foundation

enum FoodTab: String, CaseIterable { case pinned, builtin, mealSets }

struct FoodPicker: View {
    @Environment(\.dismiss) private var dismiss

    // Tabs + Search 状态
    @State private var selectedTab: FoodTab = .pinned
    @State private var query = ""
    @State private var searchPresented = false

    // 数据
    @Query private var templates: [FoodTemplate]
    @Query(sort: \MealSet.name) private var mealSets: [MealSet]

    // 回调：单品 & 套餐
    let onSelectTemplate: (FoodTemplate) -> Void
    let onSelectMealSet: ([FoodPortion]) -> Void

    init(
        onSelectTemplate: @escaping (FoodTemplate) -> Void,
        onSelectMealSet: @escaping ([FoodPortion]) -> Void = { _ in }
    ) {
        self.onSelectTemplate = onSelectTemplate
        self.onSelectMealSet = onSelectMealSet
        // 取数的排序无所谓，用英文名稳定一下；UI 内再按 localizedName 排序
        _templates = Query(sort: [SortDescriptor(\FoodTemplate.nameEN)])
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if !searchPresented {
                    HStack(spacing: 8) {
                        tabChip(.pinned,   label: String(localized: "pinned"),         systemImage: "pin.fill")
                        tabChip(.builtin,  label: String(localized: "library_builtin"), systemImage: "books.vertical.fill")
                        tabChip(.mealSets, label: String(localized: "meal_sets"),       systemImage: "fork.knife")
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                }

                List {
                    if searchPresented {
                        // —— 搜索模式：三域一起显示（空输入=显示全部） ——
                        if !pinnedTemplatesFiltered.isEmpty {
                            Section(String(localized: "pinned")) {
                                ForEach(pinnedTemplatesFiltered) { f in templateRow(f) }
                            }
                        }
                        if !builtinFiltered.isEmpty {
                            Section(String(localized: "library_builtin")) {
                                ForEach(builtinFiltered) { f in templateRow(f) }
                            }
                        }
                        if !mealSetsFiltered.isEmpty {
                            Section(String(localized: "meal_sets")) {
                                ForEach(mealSetsFiltered) { set in mealSetRow(set) }
                            }
                        }
                    } else {
                        // —— 普通模式：只显示当前 tab ——
                        switch selectedTab {
                        case .pinned:
                            let pinnedT = templates.filter { $0.isPinned }.sortedByLocalizedName()
                            if !pinnedT.isEmpty {
                                Section(String(localized: "pinned")) {
                                    ForEach(pinnedT) { f in templateRow(f) }
                                }
                            } else {
                                ContentUnavailableView(
                                    String(localized: "no_pinned"),
                                    systemImage: "pin.slash",
                                    description: Text(String(localized: "pin_hint"))
                                )
                            }

                        case .builtin:
                            ForEach(templates.sortedByLocalizedName()) { f in templateRow(f) }

                        case .mealSets:
                            ForEach(mealSetsFilteredWhenNotSearching) { set in mealSetRow(set) }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(String(localized: "choose_food"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
            }
            .searchable(
                text: $query,
                isPresented: $searchPresented, // 点搜索即进入搜索模式（按钮隐藏）
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: String(localized: "search")
            )
        }
    }

    // MARK: - 行视图
    private func templateRow(_ f: FoodTemplate) -> some View {
        LibraryRowTemplate(food: f)
            .contentShape(Rectangle())
            .onTapGesture { onSelectTemplate(f); dismiss() }
    }

    private func mealSetRow(_ set: MealSet) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(set.name).bold()
                Text("\(set.items.count) items")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "tray.and.arrow.down.fill")
                .foregroundColor(.blue)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let portions = FoodPortion.fromMealSet(set)  // ✅ 批量生成
            onSelectMealSet(portions)
            dismiss()
        }
    }

    // MARK: - 过滤 & 排序（按当前语言名）
    private var pinnedTemplatesFiltered: [FoodTemplate] {
        let base = templates.filter { $0.isPinned }
        return filterAndSort(base)
    }
    private var builtinFiltered: [FoodTemplate] {
        let base = templates // 全部内置（含 pinned，会在 UI 分区控制）
        return filterAndSort(base)
    }
    private var mealSetsFiltered: [MealSet] {
        guard !query.isEmpty else { return mealSets }
        let q = query.lowercased()
        return mealSets.filter { $0.name.lowercased().contains(q) }
    }
    private var mealSetsFilteredWhenNotSearching: [MealSet] {
        // 非搜索模式下直接全部显示
        mealSets
    }

    private func filterAndSort(_ arr: [FoodTemplate]) -> [FoodTemplate] {
        let sorted = arr.sortedByLocalizedName()
        guard !query.isEmpty else { return sorted }
        let q = query.lowercased()
        return sorted.filter { $0.localizedName.lowercased().contains(q) }
    }

    // MARK: - Tab（圆角描边）
    private func tabChip(_ tab: FoodTab, label: String, systemImage: String) -> some View {
        let isSelected = (selectedTab == tab)
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .blue : .secondary)
                Text(label)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.35), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers
private extension Array where Element == FoodTemplate {
    func sortedByLocalizedName() -> [FoodTemplate] {
        sorted {
            $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending
        }
    }
}
