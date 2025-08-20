import SwiftUI
import Charts

final class HistoryLoader {
    static let prefix = "mealcards."
    private let ud = UserDefaults.standard

    func loadAllRecords(now: Date = Date(), tz: TimeZone = .current) -> [HistoryRecord] {
        // 1) 找出所有 mealcards.* key
        let keys = ud.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(Self.prefix) }

        // 2) 解析为 (startDate, cutoffHour, key)
        var items: [(key: String, start: Date, cutoff: Int, totalKcal: Int)] = []

        for k in keys {
            guard let (start, cutoff) = Self.parseCycleKey(from: k, tz: tz) else { continue }
            guard let cards: [MealCard] = decodeCards(for: k) else { continue }
            let total = cards.reduce(0) { $0 + $1.kcal }
            items.append((k, start, cutoff, total))
        }

        // 3) 按 start 升序
        items.sort { $0.start < $1.start }

        // 4) 计算 end：下一条的 start；最后一条若“覆盖 now”，则 end=now，否则 end= start + 24h（保底）
        var records: [HistoryRecord] = []
        for (idx, it) in items.enumerated() {
            let start = it.start
            let nextStart = (idx + 1 < items.count) ? items[idx + 1].start : nil
            let end: Date? = {
                if let ns = nextStart {
                    return ns
                } else {
                    // 最后一条：如果 now >= start，认为进行中 → end=now；否则给一个兜底 24h
                    return (now >= start) ? now : Calendar.current.date(byAdding: .hour, value: 24, to: start)
                }
            }()

            records.append(HistoryRecord(key: it.key, start: start, end: end, totalKcal: it.totalKcal))
        }

        return records
    }

    private func decodeCards(for key: String) -> [MealCard]? {
        guard let data = ud.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([MealCard].self, from: data)
    }

    /// 从 "mealcards.YYYY-MM-DD@HHh" 解析出开始日期与小时
    static func parseCycleKey(from key: String, tz: TimeZone) -> (Date, Int)? {
        guard key.hasPrefix(prefix) else { return nil }
        let tail = String(key.dropFirst(prefix.count)) // "YYYY-MM-DD@HHh"
        let parts = tail.split(separator: "@")
        guard parts.count == 2 else { return nil }
        let dateStr = String(parts[0]) // "YYYY-MM-DD"
        let hourStr = String(parts[1]).replacingOccurrences(of: "h", with: "")
        guard let cutoff = Int(hourStr) else { return nil }

        var comps = DateComponents()
        comps.calendar = Calendar(identifier: .gregorian)
        comps.timeZone = tz
        let ymd = dateStr.split(separator: "-").compactMap { Int($0) }
        guard ymd.count == 3 else { return nil }
        comps.year = ymd[0]; comps.month = ymd[1]; comps.day = ymd[2]
        comps.hour = cutoff; comps.minute = 0; comps.second = 0
        return comps.date.map { ($0, cutoff) }
    }
}


extension HistoryLoader {
    /// 删除一条历史记录
    func delete(_ record: HistoryRecord) {
        ud.removeObject(forKey: record.key)
    }
}
