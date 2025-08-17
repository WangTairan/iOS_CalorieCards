import Foundation

/// 一条热量记录（将来可改为 SwiftData @Model）
struct Entry: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var kcal: Int
    var date: Date = .now
    var kind: EntryKind
}
