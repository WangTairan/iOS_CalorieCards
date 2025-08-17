import Foundation

final class MealCardStateStore {
    static let shared = MealCardStateStore()
    private let ud = UserDefaults.standard

    private func key(cycleKey: String) -> String {
        "mealcards.\(cycleKey)"
    }

    func saveAll(cards: [MealCard]) {
        let cycle = DayRollover.cycleKey()
        let k = key(cycleKey: cycle)
        if let data = try? JSONEncoder().encode(cards) {
            ud.set(data, forKey: k)
        }
    }

    func loadAll() -> [MealCard]? {
        let cycle = DayRollover.cycleKey()
        let k = key(cycleKey: cycle)
        guard let data = ud.data(forKey: k) else { return nil }
        return try? JSONDecoder().decode([MealCard].self, from: data)
    }
    
    // 兼容层：供 ExpandedKcalCard 调用
    func save(updatedCard: MealCard) {
        var cards = loadAll() ?? []
        if let idx = cards.firstIndex(where: { $0.id == updatedCard.id }) {
            cards[idx] = updatedCard
        } else {
            cards.append(updatedCard)
        }
        saveAll(cards: cards)
    }
}
