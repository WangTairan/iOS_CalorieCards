// Data/Seeding/SeedTemplatesUseCase.swift
import Foundation
import SwiftData

/// 首次运行时导入预置食材（JSON -> SwiftData）
/// 仅当库中没有任何 FoodTemplate 时执行一次；之后不再重复导入。
@MainActor
struct SeedTemplatesUseCase {
    let context: ModelContext

    func run() async throws {
        // 1) 已有数据则跳过
        var d = FetchDescriptor<FoodTemplate>(); d.fetchLimit = 1
        if (try? context.fetch(d))?.isEmpty == false { return }

        // 2) 加载所有种子条目
        let seeds = try loadAllSeedItems()

        // 3) 去重（按 nameEN，大小写敏感）
        var seen = Set<String>()
        var unique: [FoodTemplateRaw] = []
        for r in seeds {
            if !seen.contains(r.nameEN) {
                unique.append(r)
                seen.insert(r.nameEN)
            } else {
                print("⚠️ 跳过重复条目：\(r.nameEN)")
            }
        }

        // 4) 写入 SwiftData
        for r in unique {
            context.insert(FoodTemplate(
                nameZH: r.nameZH,
                nameEN: r.nameEN,
                unit: r.unit,
                kcalPerUnit: r.kcalPerUnit
            ))
        }
        try context.save()
        print("✅ 已导入 \(unique.count) 条预置食材（原始 \(seeds.count)，去重后）")
    }

    // MARK: - Loader
    private func loadAllSeedItems() throws -> [FoodTemplateRaw] {
        guard let root = Bundle.main.resourceURL else {
            throw SeedError.missingFile
        }

        let fm = FileManager.default
        var all: [FoodTemplateRaw] = []
        var found = 0

        if let en = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in en {
                if url.pathExtension.lowercased() == "json" {
                    found += 1
                    do {
                        let data = try Data(contentsOf: url)
                        let arr = try JSONDecoder().decode([FoodTemplateRaw].self, from: data)
                        all.append(contentsOf: arr)
                        print("📥 导入种子文件：\(url.lastPathComponent)，条目数=\(arr.count)")
                    } catch {
                        print("⚠️ 无法解析 \(url.lastPathComponent)：\(error)")
                    }
                }
            }
        }

        if found == 0 {
            print("⚠️ 整个 bundle 内未找到任何 .json 文件")
            throw SeedError.missingFile
        }

        return all
    }


    enum SeedError: Error { case missingFile }
}

/// JSON 解码中转结构
private struct FoodTemplateRaw: Codable {
    let nameZH: String
    let nameEN: String
    let unit: UnitKind
    let kcalPerUnit: Double
}
