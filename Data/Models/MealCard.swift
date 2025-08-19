import SwiftUI
import UIKit

struct MealCard: Identifiable, Codable, Equatable, Hashable {
    var name: CardName
    var kcal: Int
    var items: [FoodPortion]
    var manualKcalText: String?
    var appearance: CardAppearance?

    var id: String { name.id }

    init(name: CardName,
         kcal: Int = 0,
         items: [FoodPortion] = [],
         manualKcalText: String? = nil,
         appearance: CardAppearance? = nil)
    {
        self.name = name
        self.kcal = kcal
        self.items = items
        self.manualKcalText = manualKcalText
        self.appearance = appearance
    }

    var effectiveAppearance: CardAppearance {
        appearance ?? DefaultAppearance.for(name)
    }

    var displaySymbol: String { effectiveAppearance.symbol }
    var displayColor: Color  { effectiveAppearance.color }
}


struct CardAppearance: Codable, Equatable, Hashable {
    var symbol: String        // SF Symbol 名称
    var colorHex: String      // 颜色十六进制
}

extension CardAppearance {
    var color: Color { Color(hex: colorHex) }
}

// 方便编码颜色
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    var hexRGB: String {
        // 简易提取（sRGB），用于保存
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let R = Int(round(r * 255))
        let G = Int(round(g * 255))
        let B = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", R, G, B)
    }
}

struct DefaultAppearance {
    static func `for`(_ name: CardName) -> CardAppearance {
        switch name.rawValue {
        case "Breakfast":
            return .init(symbol: "sunrise", colorHex: "#007AFF")     // systemBlue
        case "Lunch":
            return .init(symbol: "fork.knife.circle", colorHex: "#007AFF")
        case "Snack":
            return .init(symbol: "takeoutbag.and.cup.and.straw", colorHex: "#FF9500") // systemOrange
        case "Dinner":
            return .init(symbol: "moon.stars", colorHex: "#007AFF")  // systemPurple 近似
        default:
            return .init(symbol: "fork.knife", colorHex: "#007AFF")
        }
    }
}
