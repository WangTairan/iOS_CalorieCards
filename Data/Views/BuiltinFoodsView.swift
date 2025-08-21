import SwiftUI
import SwiftData

struct BuiltinFoodsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FoodTemplate.nameEN) private var templates: [FoodTemplate]
    @State private var query = ""

    var filtered: [FoodTemplate] {
        guard !query.isEmpty else { return templates }
        let q = query.lowercased()
        return templates.filter {
            $0.nameEN.lowercased().contains(q) || $0.nameZH.contains(query)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { LibraryRowTemplate(food: $0) }
        }
        .navigationTitle(String(localized: "library_builtin"))
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: String(localized: "search"))
    }
}
