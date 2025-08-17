import SwiftUI
import SwiftData

struct FoodPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [FoodTemplate]
    @State private var query = ""

    /// 只返回被选中的食材
    var onSelect: (FoodTemplate) -> Void

    init(onSelect: @escaping (FoodTemplate) -> Void) {
        self.onSelect = onSelect
        _items = Query(sort: [SortDescriptor(\FoodTemplate.nameEN)])
    }

    var body: some View {
        NavigationStack {
            List(filtered(items)) { f in
                Button {
                    onSelect(f)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localizedName(f))
                            Text(unitLabel(f))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(f.kcalPerUnit)) \(String(localized: "kcal_unit"))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $query)
            .navigationTitle(String(localized: "food_library"))
        }
    }

    // MARK: - Helpers
    func filtered(_ arr: [FoodTemplate]) -> [FoodTemplate] {
        guard !query.isEmpty else { return arr }
        let q = query.lowercased()
        return arr.filter {
            localizedName($0).lowercased().contains(q)
            || $0.nameEN.lowercased().contains(q)
            || $0.nameZH.contains(query)
        }
    }

    func localizedName(_ f: FoodTemplate) -> String {
        Locale.current.language.languageCode?.identifier == "zh" ? f.nameZH : f.nameEN
    }

    func unitLabel(_ f: FoodTemplate) -> String {
        switch f.unit {
        case .per100g:
            return String(localized: "per_100g")
        case .per100ml:
            return String(localized: "per_100ml")
        case .perPiece:
            return String(localized: "per_piece")
        }
    }
}
