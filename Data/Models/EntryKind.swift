import SwiftUI

/// 餐别类型（正餐 / 零食）
enum EntryKind: String, CaseIterable, Identifiable, Codable {
    case meal
    case snack

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meal: return "正餐"
        case .snack: return "零食"
        }
    }

    var tint: Color {
        switch self {
        case .meal:  return Color(.systemBlue)
        case .snack: return Color(.systemOrange)
        }
    }

    var symbol: String {
        switch self {
        case .meal:  return "fork.knife"
        case .snack: return "takeoutbag.and.cup.and.straw"
        }
    }
}
