// Data/Modles/NutritionModels.swift
import SwiftUI

/// 编辑时的一条食材条目（快照，避免直接持有 SwiftData 对象）
struct FoodPortion: Identifiable, Hashable, Codable {
    var id = UUID()

    // 显示/计算所需的快照字段
    var nameEN: String
    var nameZH: String
    var unit: UnitKind
    var kcalPerUnit: Double

    // 用户选择的数量
    var quantity: Double

    init(template: FoodTemplate, defaultQuantity: Double) {
        self.nameEN = template.nameEN
        self.nameZH = template.nameZH
        self.unit = template.unit
        self.kcalPerUnit = template.kcalPerUnit
        self.quantity = defaultQuantity
    }

    /// 按单位计算热量
    var kcal: Double {
        switch unit {
        case .per100g, .per100ml: return kcalPerUnit * quantity / 100.0
        case .perPiece:           return kcalPerUnit * quantity
        }
    }

    /// 本地化名称
    var localizedName: String {
        let isZH = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        return isZH ? nameZH : nameEN
    }

    /// 本地化短单位
    var unitShortLocalized: String {
        let isZH = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        switch unit {
        case .per100g:  return isZH ? "克" : "g"
        case .per100ml: return isZH ? "毫升" : "ml"
        case .perPiece: return isZH ? "个" : "pc"
        }
    }
}
