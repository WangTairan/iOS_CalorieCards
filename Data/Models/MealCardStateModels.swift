import Foundation

/// 展开卡片的持久化状态（当日周期）
struct SavedMealCardState: Codable {
    var items: [FoodPortion]     // 直接存 FoodPortion（它已是 Codable）
    var manualKcalText: String
    var lastUpdated: Date
}
