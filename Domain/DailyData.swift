import SwiftData
import SwiftUI

@Model
final class DailyCard {
    var date: Date            // 这张卡属于哪一天（仅用到日）
    var kindRaw: String       // "breakfast"/"lunch"/"snack"/"dinner"
    var kcal: Int

    init(date: Date, kind: CardKind, kcal: Int = 0) {
        self.date = date.stripToDay()
        self.kindRaw = kind.rawValue
        self.kcal = kcal
    }

    var kind: CardKind {
        get { CardKind(rawValue: kindRaw) ?? .breakfast }
        set { kindRaw = newValue.rawValue }
    }
}

extension Date {
    func stripToDay(cal: Calendar = .current) -> Date {
        cal.startOfDay(for: self)
    }
}
