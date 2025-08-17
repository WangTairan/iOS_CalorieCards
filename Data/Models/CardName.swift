import SwiftUI

struct CardName: Codable, Hashable, Identifiable {
    let rawValue: String
    var id: String { rawValue }

    static let breakfast = CardName(rawValue: "breakfast")
    static let lunch     = CardName(rawValue: "lunch")
    static let snack     = CardName(rawValue: "snack")
    static let dinner    = CardName(rawValue: "dinner")

    var title: String {
        switch rawValue {
        case "breakfast": return String(localized: "breakfast")
        case "lunch":     return String(localized: "lunch")
        case "snack":     return String(localized: "snack")
        case "dinner":    return String(localized: "dinner")
        default:          return rawValue.capitalized
        }
    }
}
