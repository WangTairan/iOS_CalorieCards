import Foundation
import SwiftData

/// 首次运行时导入预置食材（JSON -> SwiftData）
@MainActor
struct SeedTemplatesUseCase {
    let context: ModelContext

    func run() async throws {
        // 1) 已有数据则跳过
        var d = FetchDescriptor<FoodTemplate>(); d.fetchLimit = 1
        if (try? context.fetch(d))?.isEmpty == false { return }

        // 2) 读取 JSON
        guard let url = Bundle.main.url(forResource: "FoodTemplates", withExtension: "json") else {
            throw SeedError.missingFile
        }
        let data = try Data(contentsOf: url)
        let raw = try JSONDecoder().decode([FoodTemplateRaw].self, from: data)

        // 3) 写入 SwiftData
        for r in raw {
            context.insert(FoodTemplate(key: r.key, nameZH: r.nameZH, nameEN: r.nameEN,
                                        unit: r.unit, kcalPerUnit: r.kcalPerUnit))
        }
        try context.save()
        print("✅ 已导入 \(raw.count) 条预置食材")
    }

    enum SeedError: Error { case missingFile }
}

/// 仅用于 JSON 解码的中转结构
private struct FoodTemplateRaw: Codable {
    let key, nameZH, nameEN: String
    let unit: UnitKind
    let kcalPerUnit: Double
}
