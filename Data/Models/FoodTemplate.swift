import SwiftData

enum UnitKind: String, Codable, CaseIterable {
    case per100g, per100ml, perPiece
}

@Model
final class FoodTemplate {
    @Attribute(.unique) var key: String
    var nameZH: String
    var nameEN: String
    var unit: UnitKind
    var kcalPerUnit: Double

    init(key: String, nameZH: String, nameEN: String, unit: UnitKind, kcalPerUnit: Double) {
        self.key = key
        self.nameZH = nameZH
        self.nameEN = nameEN
        self.unit = unit
        self.kcalPerUnit = kcalPerUnit
    }
}
