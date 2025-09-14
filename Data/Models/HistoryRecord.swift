import SwiftUI

struct HistoryRecord: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let start: Date
    let end: Date?
    let totalKcal: Int

    // ⬇️ 新增：三大营养素总量（单位 g）
    let totalProtein: Int
    let totalCarb: Int
    let totalFat: Int

    var durationHours: Double {
        guard let end else { return 0 }
        return max(0, end.timeIntervalSince(start) / 3600.0)
    }

    var isCurrentCycle: Bool { end == nil }
}
