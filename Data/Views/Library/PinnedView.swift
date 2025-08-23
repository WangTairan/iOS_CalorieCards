import SwiftUI
import SwiftData

struct PinnedView: View {
    @Query private var templates: [FoodTemplate]
    @State private var query = ""

    init() {
        _templates = Query(sort: [SortDescriptor(\FoodTemplate.nameEN, order: .forward)])
    }

    private var pinnedFiltered: [FoodTemplate] {
        let pinned = templates.filter { $0.isPinned }
        let sorted = pinned.sortedByLocalizedName()
        guard !query.isEmpty else { return sorted }
        let q = query.lowercased()
        return sorted.filter { $0.localizedName.lowercased().contains(q) }
    }

    var body: some View {
        List {
            Section(String(localized: "content")) {
                if pinnedFiltered.isEmpty {
                    Text(String(localized: "no_pinned"))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)   // ❌ 空态不需要分割线
                } else {
                    ForEach(pinnedFiltered) { food in
                        LibraryRowTemplate(food: food)
                            .listRowSeparator(.visible)                   // ✅ 明确显示
                            .listRowSeparatorTint(.secondary.opacity(0.3)) // ✅ 颜色微调
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(String(localized: "pinned"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "search")
        )
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
