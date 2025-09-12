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
                    ForEach(pinned) { food in
                        LibraryRowTemplate(food: food)
                            .contentShape(Rectangle())
                            .listRowSeparator(.visible)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(String(localized: "edit")) {
                                    editingFood = food
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
            }

            Section(String(localized: "all_foods")) {
                ForEach(others) { food in
                    LibraryRowTemplate(food: food)
                        .contentShape(Rectangle())
                        .listRowSeparator(.visible)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(String(localized: "edit")) {
                                editingFood = food
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
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(String(localized: "food_library"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "search")
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: {
                    Text(String(localized: "add_food"))
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddFoodView()
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(20)
        }
        .sheet(item: $editingFood) { food in
            EditFoodView(food: food)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(20)
        }
    }
}
