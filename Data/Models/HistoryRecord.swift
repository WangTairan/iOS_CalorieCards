import SwiftUI

struct HistoryRecord: Identifiable, Hashable {
    let id = UUID()
    let key: String                  // "mealcards.YYYY-MM-DD@HHh"
    let start: Date                  // 由 key 解析
    let end: Date?                   // 通过“下一条 start”或“now”推算
    let totalKcal: Int               // 解码 MealCard[] 求和

    var durationHours: Double {
        guard let end else { return 0 }
        return max(0, end.timeIntervalSince(start) / 3600.0)
    }

    var isCurrentCycle: Bool { end == nil } // 还在进行中的记录（会在 loader 里把 end 填“now”）
}
