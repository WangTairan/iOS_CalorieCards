import Foundation

final class HistoryLoader {
    private let ud = UserDefaults.standard
    private let prefix = "mealcards."

    func loadAllRecords(now: Date = Date()) -> [HistoryRecord] {
        let mgr = DayCycleManager.shared
        let currentCycleKey = mgr.currentCycleKey()

        // 1) 找到所有 mealcards.* 的 key，并解析出 start（来自 key 的 ISO8601）
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withDashSeparatorInDate]

        struct Entry {
            let storageKey: String   // 例如 "mealcards.2025-08-22T02:00:00Z"
            let start: Date
            let cards: [MealCard]?   // 该天的卡片
            let isCurrent: Bool
        }

        var entries: [Entry] = []

        for key in ud.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            let iso = String(key.dropFirst(prefix.count))
            guard let start = fmt.date(from: iso) else { continue }
            let cards = (ud.data(forKey: key)).flatMap { try? JSONDecoder().decode([MealCard].self, from: $0) }
            let isCurrent = (iso == currentCycleKey)
            entries.append(Entry(storageKey: key, start: start, cards: cards, isCurrent: isCurrent))
        }

        // 没有任何 key：返回空
        if entries.isEmpty { return [] }

        // 2) 按 start 升序排序
        entries.sort { $0.start < $1.start }

        // 3) 生成 HistoryRecord（历史 end = 下一条 start；当前 end = min(now, nextSwitch)）
        var records: [HistoryRecord] = []
        for (i, e) in entries.enumerated() {
            let end: Date = {
                if i + 1 < entries.count {
                    return entries[i + 1].start       // 下一天开始 = 本天结束
                } else {
                    // 最后一条
                    if e.isCurrent {
                        return min(now, mgr.nextSwitch)
                    } else {
                        // 兜底：没遇到过，但以 24h 做结束，避免 duration=0
                        return e.start.addingTimeInterval(24 * 3600)
                    }
                }
            }()

            let total = (e.cards ?? []).reduce(0) { $0 + $1.kcal }
            records.append(
                HistoryRecord(
                    key: e.storageKey,
                    start: e.start,
                    end: end,
                    totalKcal: total
                )
            )
        }

        return records
    }

    func delete(_ record: HistoryRecord) {
        ud.removeObject(forKey: record.key)
    }
}
