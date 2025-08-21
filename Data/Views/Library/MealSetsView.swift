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
            ForEach(filtered) { set in
                NavigationLink {
                    MealSetDetail(set: set)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(set.name).bold()
                        Text("\(set.items.count) items")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { idx in
                idx.map { filtered[$0] }.forEach(context.delete)
                try? context.save()
            }

            Button { showingNew = true } label: {
                Label(String(localized: "new_meal_set"), systemImage: "fork.knife")
            }
        }
        .navigationTitle(String(localized: "meal_sets"))
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "search")
        )
        .sheet(isPresented: $showingNew) { MealSetEditor() }
    }
}
