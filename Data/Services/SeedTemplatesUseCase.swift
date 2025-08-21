// Data/Seeding/SeedTemplatesUseCase.swift
import Foundation
import SwiftData

/// 首次运行时导入预置食材（JSON -> SwiftData）
/// 仅当库中没有任何 FoodTemplate 时执行一次；之后不再重复导入。
@MainActor
struct SeedTemplatesUseCase {
    let context: ModelContext

    func run() async throws {
        // 1) 已有数据则跳过（只要存在任意 FoodTemplate）
        var d = FetchDescriptor<FoodTemplate>(); d.fetchLimit = 1
        if (try? context.fetch(d))?.isEmpty == false { return }

        // 2) 读取 JSON
        guard let url = Bundle.main.url(forResource: "FoodTemplates", withExtension: "json") else {
            throw SeedError.missingFile
        }
        let data = try Data(contentsOf: url)
        let raw = try JSONDecoder().decode([FoodTemplateRaw].self, from: data)

        // 3) 写入 SwiftData（无需 key）
        for r in raw {
            context.insert(FoodTemplate(
                nameZH: r.nameZH,
                nameEN: r.nameEN,
                unit: r.unit,
                kcalPerUnit: r.kcalPerUnit
            ))
        }
        try context.save()
        print("✅ 已导入 \(raw.count) 条预置食材")
    }

    enum SeedError: Error { case missingFile }
}

/// 仅用于 JSON 解码的中转结构
/// 注意：即使 JSON 有 `key` 字段，这里不声明它即可被忽略
private struct FoodTemplateRaw: Codable {
    let nameZH: String
    let nameEN: String
    let unit: UnitKind
    let kcalPerUnit: Double

    // 如果你的 JSON 里确实有 key，也可以这样兼容但不使用：
//    let key: String?
//    enum CodingKeys: String, CodingKey { case nameZH, nameEN, unit, kcalPerUnit, key }
}
