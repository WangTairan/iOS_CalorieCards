import SwiftUI
import SwiftData

struct MealSetsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MealSet.name) private var mealSets: [MealSet]
    @State private var showingNew = false
    @State private var query = ""

    private var filtered: [MealSet] {
        guard !query.isEmpty else { return mealSets }
        let q = query.lowercased()
        return mealSets.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        List {
            // ✅ 和 HistoryListView 一样的系统 header 风格
            Section(String(localized: "sets")) {
                if filtered.isEmpty {
                    Text(String(localized: "no_history_yet"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filtered.indices, id: \.self) { idx in
                        let set = filtered[idx]
                        NavigationLink {
                            MealSetDetail(set: set)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(set.name).bold()
                                Text("mealset_items_count \(set.items.count)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        // ✅ 让第一行和 header 之间显示分割线
                        .listRowSeparator(idx == 0 ? .visible : .automatic)
                    }
                    .onDelete { idx in
                        idx.map { filtered[$0] }.forEach(context.delete)
                        try? context.save()
                    }

                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden) // 背景透明
        .background(Color.clear)
        .navigationTitle(String(localized: "meal_sets"))
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "search")
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNew = true
                } label: {
                    // 只要文字，不要图标
                    Text(String(localized: "new_meal_set"))
                }
            }
        }
        .sheet(isPresented: $showingNew) {
            MealSetEditor()
        }
    }
}
