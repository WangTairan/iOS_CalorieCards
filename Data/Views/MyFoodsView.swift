import SwiftUI
import SwiftData

struct MyFoodsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \UserFood.name) private var myFoods: [UserFood]
    @State private var showingAdd = false
    @State private var query = ""

    private var filtered: [UserFood] {
        guard !query.isEmpty else { return myFoods }
        let q = query.lowercased()
        return myFoods.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        List {
            ForEach(filtered) { LibraryRowUserFood(food: $0) }
                .onDelete { idx in
                    idx.map { filtered[$0] }.forEach(context.delete)
                    try? context.save()
                }

            Button { showingAdd = true } label: {
                Label(String(localized: "add_food"), systemImage: "plus.circle")
            }
        }
        .navigationTitle(String(localized: "my_foods"))
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "search")
        )
        .sheet(isPresented: $showingAdd) { AddFoodView() }
    }
}
