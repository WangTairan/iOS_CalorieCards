import Foundation

final class HistoryLoader {
    private let ud = UserDefaults.standard
    private let prefix = "mealcards."

    func loadAllRecords(now: Date = Date()) -> [HistoryRecord] {
        let mgr = DayCycleManager.shared
        let currentCycleKey = mgr.currentCycleKey()

        // 1) 扫描所有 "mealcards.*" key
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withDashSeparatorInDate]

        struct Entry {
            let storageKey: String      // "mealcards.<ISO8601>"
            let start: Date             // 逻辑日开始
            let cards: [MealCard]?      // 该日卡片（可能为 nil）
            let isCurrent: Bool         // 是否为当前进行中的周期
        }

        var entries: [Entry] = []

        for key in ud.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            let iso = String(key.dropFirst(prefix.count))
            guard let start = fmt.date(from: iso) else { continue }
            let cards = (ud.data(forKey: key)).flatMap { try? JSONDecoder().decode([MealCard].self, from: $0) }
            let isCurrent = (iso == currentCycleKey)
            entries.append(.init(storageKey: key, start: start, cards: cards, isCurrent: isCurrent))
        }

        // 没有任何历史：返回空
        if entries.isEmpty { return [] }

        // 2) 按 start 升序
        entries.sort { $0.start < $1.start }

        // 3) 生成 HistoryRecord
        //    - 有下一条：先用下一条 start 当 end；若跨多天，则裁到“该条 start 的下一个 cutoff”
        //    - 没有下一条：
        //        - 若是当前周期：end = min(now, nextSwitch)（进行中，随 now 变化）
        //        - 若非当前：end = “该条 start 的下一个 cutoff”（单天封口）
        var records: [HistoryRecord] = []
        let tz = TimeZone.current

        for (i, e) in entries.enumerated() {
            // 当天的“单天封口”边界 = 从 e.start 起，下一个 cutoff 本地时刻（DST 友好，可能是 23/24/25h）
            let cutoffHour = Calendar(identifier: .gregorian)
                .dateComponents(in: tz, from: e.start).hour ?? 0
            let oneDayBoundary = Self.nextOccurrence(ofHour: cutoffHour, after: e.start, tz: tz)

            // 先算候选 end
            let candidateEnd: Date = {
                if i + 1 < entries.count {
                    return entries[i + 1].start
                } else {
                    if e.isCurrent {
                        return min(now, mgr.nextSwitch)
                    } else {
                        return oneDayBoundary
                    }
                }
            }()

            // 最终 end：不超过“单天封口”边界
            let end = min(candidateEnd, oneDayBoundary)

            // 保证正时长再加入
            if end > e.start {
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
        }

        return records
    }

    func delete(_ record: HistoryRecord) {
        ud.removeObject(forKey: record.key)
    }

    // MARK: - Helpers

    /// 从某时刻之后的“下一个指定小时”的本地时间（作为逻辑日切换点；DST 友好）
    private static func nextOccurrence(ofHour hour: Int, after: Date, tz: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        var comps = cal.dateComponents(in: tz, from: after)
        comps.hour = hour
        comps.minute = 0
        comps.second = 0
        var candidate = cal.date(from: comps)

        if candidate == nil || candidate! <= after {
            let nextDay = cal.date(byAdding: .day, value: 1, to: after)!
            comps = cal.dateComponents(in: tz, from: nextDay)
            comps.hour = hour
            comps.minute = 0
            comps.second = 0
            candidate = cal.date(from: comps)
        }
        return candidate ?? after.addingTimeInterval(24 * 3600)
    }
}
