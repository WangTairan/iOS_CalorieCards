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
    
    func loadOrInitCards() -> [MealCard] {
        let currentKey = DayRollover.cycleKey()
        let currentStorageKey = key(cycleKey: currentKey)

        // 1. 尝试加载今天的
        if let data = ud.data(forKey: currentStorageKey),
           let cards = try? JSONDecoder().decode([MealCard].self, from: data) {
            return cards
        }

        // 2. 找最近的一个历史 cycleKey
        // 注意：UserDefaults 是个 K-V 存储，我们只能自己过滤
        let prefix = "mealcards."
        let allKeys = ud.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) && $0 != currentStorageKey }
            .sorted(by: >) // 新的在前

        if let latestKey = allKeys.first,
           let data = ud.data(forKey: latestKey),
           let oldCards = try? JSONDecoder().decode([MealCard].self, from: data) {

            // 继承结构但清零
            let reset = oldCards.map { $0.cleared() }
            saveAll(cards: reset)
            return reset
        }

        // 3. 最后才退回默认
        let defaults = [
            MealCard(name: .breakfast),
            MealCard(name: .lunch),
            MealCard(name: .snack),
            MealCard(name: .dinner)
        ]
        saveAll(cards: defaults)
        return defaults
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
