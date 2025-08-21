import SwiftUI
import SwiftData

@main
struct CalorieCardsApp: App {
    var body: some Scene {
        WindowGroup { AppBootstrapper() }
            .modelContainer(for: [FoodTemplate.self, MealSet.self, MealSetItem.self])
    }
}
