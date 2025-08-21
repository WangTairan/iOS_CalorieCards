// Data/Models/Models.swift
import SwiftData
import Foundation


enum UnitKind: String, Codable, CaseIterable {
    case per100g, per100ml, perPiece
}

@Model
final class FoodTemplate {
    // 多语言名字（内置有中英；新建时两个都设为同一输入）
    var nameZH: String
    var nameEN: String

    var unit: UnitKind
    var kcalPerUnit: Double
    var isPinned: Bool = false

    init(nameZH: String, nameEN: String, unit: UnitKind, kcalPerUnit: Double, isPinned: Bool = false) {
        self.nameZH = nameZH
        self.nameEN = nameEN
        self.unit = unit
        self.kcalPerUnit = kcalPerUnit
        self.isPinned = isPinned
    }

    // 当前语言显示名
    var localizedName: String {
        let isZH = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        return isZH ? nameZH : nameEN
    }

    // 单位本地化
    var unitLabel: String {
        switch unit {
        case .perPiece:  return String(localized: "per_piece")
        case .per100g:   return String(localized: "per_100g")
        case .per100ml:  return String(localized: "per_100ml")
        }
    }
}

@Model
final class MealSet {
    var name: String
    var note: String?
    @Relationship(deleteRule: .cascade) var items: [MealSetItem]

    init(name: String, note: String? = nil, items: [MealSetItem] = []) {
        self.name = name
        self.note = note
        self.items = items
    }
}

@Model
final class MealSetItem {
    var template: FoodTemplate
    var defaultQuantity: Double

    init(template: FoodTemplate, defaultQuantity: Double) {
        self.template = template
        self.defaultQuantity = defaultQuantity
    }
}
