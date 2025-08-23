import Foundation

final class MealCardStateStore {
    static let shared = MealCardStateStore()
    private let ud = UserDefaults.standard
    private let prefix = "mealcards."

    // 统一的 Key 生成（以逻辑日 key 为命名空间）
    private func key(cycleKey: String) -> String { "\(prefix)\(cycleKey)" }

    /// 保存当前逻辑日的全部卡片
    func saveAll(cards: [MealCard]) {
        let cycle = DayCycleManager.shared.currentCycleKey()
        let k = key(cycleKey: cycle)
        if let data = try? JSONEncoder().encode(cards) {
            ud.set(data, forKey: k)
        }
    }

    /// 加载今天的卡片；若无则继承最近一次历史结构并清零；再无则初始化默认
    func loadOrInitCards() -> [MealCard] {
        let currentKey = DayCycleManager.shared.currentCycleKey()
        let currentStorageKey = key(cycleKey: currentKey)

        // 1) 直接尝试“今天”
        if let data = ud.data(forKey: currentStorageKey),
           let cards = try? JSONDecoder().decode([MealCard].self, from: data) {
            return cards
        }

        // 2) 找最近的历史周期（按 key 倒序；ISO8601 的 currentCycleKey 天然可字典序比较）
        let allKeys = ud.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) && $0 != currentStorageKey }
            .sorted(by: >)

        if let latestKey = allKeys.first,
           let data = ud.data(forKey: latestKey),
           let oldCards = try? JSONDecoder().decode([MealCard].self, from: data) {

            // 继承结构但清零
            let reset = oldCards.map { $0.cleared() }
            saveAll(cards: reset)
            return reset
        }

        // 3) 最后退回默认
        let defaults = [
            MealCard(name: .breakfast),
            MealCard(name: .lunch),
            MealCard(name: .snack),
            MealCard(name: .dinner)
        ]
        saveAll(cards: defaults)
        return defaults
    }

    /// 读取当前逻辑日的全部卡片（可能为 nil）
    func loadAll() -> [MealCard]? {
        let cycle = DayCycleManager.shared.currentCycleKey()
        let k = key(cycleKey: cycle)
        guard let data = ud.data(forKey: k) else { return nil }
        return try? JSONDecoder().decode([MealCard].self, from: data)
    }

    /// 兼容层：保存单张卡片到“今天”并落盘
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
