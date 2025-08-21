import SwiftUI
import SwiftData

struct PinnedView: View {
    @Query private var templates: [FoodTemplate]
    @State private var query = ""

    init() {
        // 先按英文名取回，UI 再按 localizedName 排序，避免顺序抖动
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
            if pinnedFiltered.isEmpty {
                ContentUnavailableView(
                    String(localized: "no_pinned"),
                    systemImage: "pin.slash",
                    description: Text(String(localized: "pin_hint"))
                )
            } else {
                ForEach(pinnedFiltered) { food in
                    LibraryRowTemplate(food: food)
                }
            }
        }
        .navigationTitle(String(localized: "pinned"))
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
