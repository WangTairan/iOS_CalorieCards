import Foundation

struct DayRollover {
    static var cutoffHour: Int {
        get {
            let v = UserDefaults.standard.object(forKey: "rollover.cutoffHour") as? Int
            return v ?? 0        // 默认 0 点
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "rollover.cutoffHour")
        }
    }

    static func cycleKey(now: Date = Date(), tz: TimeZone = .current) -> String {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents(in: tz, from: now)
        let hour = comps.hour ?? 0
        var base = now
        if hour < cutoffHour, let prev = cal.date(byAdding: .day, value: -1, to: now) {
            base = prev
        }
        let c = cal.dateComponents(in: tz, from: base)
        let y = c.year!, m = c.month!, d = c.day!
        return String(format: "%04d-%02d-%02d@%dh", y, m, d, cutoffHour)
    }
}
