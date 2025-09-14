import SwiftUI
import UIKit

struct MealCard: Identifiable, Codable, Equatable, Hashable {
    var name: CardName
    var kcal: Int
    var protein: Int            // 蛋白质（g）
    var carb: Int               // 碳水（g）
    var fat: Int                // 脂肪（g）
    var items: [FoodPortion]

    // 额外手动输入（kcal 已有；新增三大营养素手动文本，便于持久化）
    var manualKcalText: String?
    var manualProteinText: String?   // 新增
    var manualCarbText: String?      // 新增
    var manualFatText: String?       // 新增

    var appearance: CardAppearance?

    var id: String { name.id }

    init(
        name: CardName,
        kcal: Int = 0,
        protein: Int = 0,
        carb: Int = 0,
        fat: Int = 0,
        items: [FoodPortion] = [],
        manualKcalText: String? = nil,
        manualProteinText: String? = nil,
        manualCarbText: String? = nil,
        manualFatText: String? = nil,
        appearance: CardAppearance? = nil
    ) {
        self.name = name
        self.kcal = kcal
        self.protein = protein
        self.carb = carb
        self.fat = fat
        self.items = items
        self.manualKcalText = manualKcalText
        self.manualProteinText = manualProteinText
        self.manualCarbText = manualCarbText
        self.manualFatText = manualFatText
        self.appearance = appearance
    }

    var effectiveAppearance: CardAppearance {
        appearance ?? DefaultAppearance.for(name)
    }

    var displaySymbol: String { effectiveAppearance.symbol }
    var displayColor: Color  { effectiveAppearance.color }

    /// 返回清零后的卡片（保留样式、名字，但去掉数据与手动文本）
    func cleared() -> MealCard {
        MealCard(
            name: self.name,
            kcal: 0,
            protein: 0,
            carb: 0,
            fat: 0,
            items: [],
            manualKcalText: nil,
            manualProteinText: nil,
            manualCarbText: nil,
            manualFatText: nil,
            appearance: self.appearance
        )
    }
}

struct CardAppearance: Codable, Equatable, Hashable {
    var symbol: String        // SF Symbol 名称
    var colorHex: String      // 颜色十六进制

    var color: Color { Color(hex: colorHex) }
}

// 方便编码颜色
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }

        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)

        let r, g, b: Double
        switch s.count {
        case 3: // 支持 #RGB
            r = Double((v >> 8) & 0xF) / 15.0
            g = Double((v >> 4) & 0xF) / 15.0
            b = Double(v & 0xF) / 15.0
        default: // 默认 #RRGGBB
            r = Double((v >> 16) & 0xFF) / 255.0
            g = Double((v >> 8) & 0xFF) / 255.0
            b = Double(v & 0xFF) / 255.0
        }

        self = Color(red: r, green: g, blue: b)
    }

    // sRGB → "#RRGGBB"
    var hexRGB: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // 兜底：无法解析（如动态/系统色）时返回默认蓝色
            return "#007AFF"
        }
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
            return .init(symbol: "moon.stars", colorHex: "#007AFF")  // systemBlue 近似
        default:
            return .init(symbol: "fork.knife", colorHex: "#007AFF")
        }
    }
}
