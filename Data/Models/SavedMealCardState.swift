final class MealCardStateStore {
    static let shared = MealCardStateStore()
    private let ud = UserDefaults.standard

    private func makeKey(cardID: String, cycleKey: String) -> String {
        "mealcard.state.\(cardID).\(cycleKey)"
    }

    func save(cardID: String, items: [FoodPortion], manual: String) {
        let cycle = DayRollover.cycleKey()
        let key = makeKey(cardID: cardID, cycleKey: cycle)

        let payload = SavedMealCardState(
            items: items.map(PersistedFoodPortion.init),
            manualKcalText: manual,
            lastUpdated: Date()
        )
        if let data = try? JSONEncoder().encode(payload) {
            ud.set(data, forKey: key)
        }
    }

    /// 从当前周期读取；找不到则返回 nil
    func load(cardID: String) -> SavedMealCardState? {
        let cycle = DayRollover.cycleKey()
        let key = makeKey(cardID: cardID, cycleKey: cycle)
        guard let data = ud.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SavedMealCardState.self, from: data)
    }
}
