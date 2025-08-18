import SwiftUI

struct CardName: Codable, Hashable, Identifiable {
    let rawValue: String
    var id: String { rawValue }

    static let breakfast = CardName(rawValue: "Breakfast")
    static let lunch     = CardName(rawValue: "Lunch")
    static let snack     = CardName(rawValue: "Snack")
    static let dinner    = CardName(rawValue: "Dinner")

    var title: String {
        switch rawValue {
        case "Breakfast": return String(localized: "breakfast")
        case "Lunch":     return String(localized: "lunch")
        case "Snack":     return String(localized: "snack")
        case "Dinner":    return String(localized: "dinner")
        default:          return rawValue.capitalized
        }
    }
}
