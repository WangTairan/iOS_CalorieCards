import SwiftUI
import Foundation

// 套餐条目（作为卡片里的一个“集合型项目”）
struct MealSetEntry: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String                 // 套餐显示名
    var items: [FoodPortion]         // 套餐内明细（定义为“1 份”）
    var manualKcalText: String?      // 套餐额外热量（仅 kcal；空/非法视为 0）

    // 汇总（含套餐额外热量；三大营养素不叠加手动）
    var kcal: Double {
        let base = items.reduce(0) { $0 + $1.kcal }
        let extra = max(0, Int(manualKcalText ?? "") ?? 0)
        return base + Double(extra)
    }
    var protein: Double { items.reduce(0) { $0 + $1.protein } }
    var carb: Double    { items.reduce(0) { $0 + $1.carb    } }
    var fat: Double     { items.reduce(0) { $0 + $1.fat     } }
}

// 卡片的一行条目：单食物 or 套餐
enum CardEntry: Identifiable, Hashable, Codable {
    case food(FoodPortion)
    case mealSet(MealSetEntry)

    var id: UUID {
        switch self {
        case .food(let f):    return f.id
        case .mealSet(let s): return s.id
        }
    }

    // 统一显示名
    var title: String {
        switch self {
        case .food(let f):    return f.localizedName
        case .mealSet(let s): return s.name
        }
    }

    // 统一汇总
    var totalKcal: Double {
        switch self {
        case .food(let f):    return f.kcal
        case .mealSet(let s): return s.kcal
        }
    }
    var totalProtein: Double {
        switch self {
        case .food(let f):    return f.protein
        case .mealSet(let s): return s.protein
        }
    }
    var totalCarb: Double {
        switch self {
        case .food(let f):    return f.carb
        case .mealSet(let s): return s.carb
        }
    }
    var totalFat: Double {
        switch self {
        case .food(let f):    return f.fat
        case .mealSet(let s): return s.fat
        }
    }
}
