import SwiftUI
import Foundation

struct FoodPortion: Identifiable, Hashable, Codable {
    var id = UUID()

    // 显示/计算所需的快照字段（来自 FoodTemplate）
    var nameEN: String
    var nameZH: String
    var unit: UnitKind
    var kcalPerUnit: Double
    var proteinPerUnit: Double   // 新增：每单位蛋白质（g）
    var carbPerUnit: Double      // 新增：每单位碳水（g）
    var fatPerUnit: Double       // 新增：每单位脂肪（g）

    // 当前份量
    var quantity: Double

    // MARK: - 初始化
    init(template: FoodTemplate, defaultQuantity: Double) {
        self.nameEN = template.nameEN
        self.nameZH = template.nameZH
        self.unit = template.unit
        self.kcalPerUnit = template.kcalPerUnit
        self.proteinPerUnit = template.proteinPerUnit
        self.carbPerUnit = template.carbPerUnit
        self.fatPerUnit = template.fatPerUnit
        self.quantity = defaultQuantity
    }

    /// 从套餐条目构造（条目指向 FoodTemplate）
    init?(item: MealSetItem) {
        self.init(template: item.template, defaultQuantity: item.defaultQuantity)
    }

    /// 从套餐批量生成份量
    static func fromMealSet(_ set: MealSet) -> [FoodPortion] {
        set.items.compactMap { FoodPortion(item: $0) }
    }

    // MARK: - 计算值（按单位换算）
    var kcal: Double {
        switch unit {
        case .per100g, .per100ml: return kcalPerUnit * quantity / 100.0
        case .perPiece:           return kcalPerUnit * quantity
        }
    }

    var protein: Double {
        switch unit {
        case .per100g, .per100ml: return proteinPerUnit * quantity / 100.0
        case .perPiece:           return proteinPerUnit * quantity
        }
    }

    var carb: Double {
        switch unit {
        case .per100g, .per100ml: return carbPerUnit * quantity / 100.0
        case .perPiece:           return carbPerUnit * quantity
        }
    }

    var fat: Double {
        switch unit {
        case .per100g, .per100ml: return fatPerUnit * quantity / 100.0
        case .perPiece:           return fatPerUnit * quantity
        }
    }

    // MARK: - 本地化显示名
    var localizedName: String {
        let isZH = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        return isZH ? nameZH : nameEN
    }

    // MARK: - 单位本地化
    var unitShortLocalized: String {
        let isZH = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        switch unit {
        case .per100g:  return isZH ? "克" : "g"
        case .per100ml: return isZH ? "毫升" : "ml"
        case .perPiece: return isZH ? "个" : "pc"
        }
    }
}
