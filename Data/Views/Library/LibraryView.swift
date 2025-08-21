import SwiftUI
import SwiftData

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    PinnedView()
                } label: {
                    LibraryEntryRow(title: String(localized: "pinned"),
                                    systemImage: "pin.fill")
                }

                NavigationLink {
                    AllFoodsView() // ← 合并后的入口
                } label: {
                    LibraryEntryRow(title: String(localized: "food_library"),
                                    systemImage: "books.vertical.fill")
                }

                NavigationLink {
                    MealSetsView()
                } label: {
                    LibraryEntryRow(title: String(localized: "meal_sets"),
                                    systemImage: "fork.knife")
                }
            }
            .navigationTitle(String(localized: "library"))
        }
    }
}

private struct LibraryEntryRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .padding(10)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))

            Text(title).font(.headline)

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}
