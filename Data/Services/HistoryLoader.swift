import Foundation

final class HistoryLoader {
    private let ud = UserDefaults.standard
    private let prefix = "mealcards."

    func loadAllRecords(now: Date = Date()) -> [HistoryRecord] {
        let mgr = DayCycleManager.shared
        let currentCycleKey = mgr.currentCycleKey()

        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withDashSeparatorInDate]

        struct Entry {
            let storageKey: String
            let start: Date
            let cards: [MealCard]?
            let isCurrent: Bool
        }

        var entries: [Entry] = []

        for key in ud.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            let iso = String(key.dropFirst(prefix.count))
            guard let start = fmt.date(from: iso) else { continue }
            let cards = (ud.data(forKey: key)).flatMap { try? JSONDecoder().decode([MealCard].self, from: $0) }
            let isCurrent = (iso == currentCycleKey)
            entries.append(.init(storageKey: key, start: start, cards: cards, isCurrent: isCurrent))
        }

        if entries.isEmpty { return [] }
        entries.sort { $0.start < $1.start }

        var records: [HistoryRecord] = []
        let tz = TimeZone.current

        for (i, e) in entries.enumerated() {
            let cutoffHour = Calendar(identifier: .gregorian)
                .dateComponents(in: tz, from: e.start).hour ?? 0
            let oneDayBoundary = Self.nextOccurrence(ofHour: cutoffHour, after: e.start, tz: tz)

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

            let end = min(candidateEnd, oneDayBoundary)

            if end > e.start {
                let cards = e.cards ?? []

                // ⬇️ 同时汇总 kcal / P / C / F
                let totalKcal    = cards.reduce(0) { $0 + $1.kcal }
                let totalProtein = cards.reduce(0) { $0 + $1.protein }
                let totalCarb    = cards.reduce(0) { $0 + $1.carb }
                let totalFat     = cards.reduce(0) { $0 + $1.fat }

                records.append(
                    HistoryRecord(
                        key: e.storageKey,
                        start: e.start,
                        end: end,
                        totalKcal: totalKcal,
                        totalProtein: totalProtein,
                        totalCarb: totalCarb,
                        totalFat: totalFat
                    )
                )
            }
        }

        return records
    }

    func delete(_ record: HistoryRecord) {
        ud.removeObject(forKey: record.key)
    }

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
