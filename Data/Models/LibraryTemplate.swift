import SwiftUI
import SwiftData

struct LibraryRowTemplate: View {
    @Environment(\.modelContext) private var context
    @Bindable var food: FoodTemplate

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(food.nameEN).bold()
                Text(food.unitLabel).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(food.kcalPerUnit)) kcal").monospacedDigit().foregroundStyle(.secondary)
            Button {
                food.isPinned.toggle(); try? context.save()
            } label: { Image(systemName: food.isPinned ? "pin.fill" : "pin") }
            .buttonStyle(.plain)
        }
    }
}
