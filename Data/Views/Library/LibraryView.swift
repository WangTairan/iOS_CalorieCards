import SwiftUI
import SwiftData

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    AllFoodsView()
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)         // ✅ 透明背景
            .listRowSeparator(.visible)               // ✅ 分割线可见
            .navigationTitle(String(localized: "library"))
            .navigationBarTitleDisplayMode(.inline)   // ✅ inline 标题
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

            Text(title)
                .font(.headline)

            Spacer() // NavigationLink 自带 chevron，不要重复
        }
        .contentShape(Rectangle())
    }
}
