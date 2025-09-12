// Data/Seeding/SeedTemplatesUseCase.swift
import Foundation
import SwiftData

// MARK: - Config（最简：默认只首导；手动 forceReseed 触发再导；seedVersion 仅作标记）
enum SeedConfig {
    /// 手动强制：为 true 时，每次启动都执行“增量导入”（仅插入库中不存在的条目）
    static var forceReseed: Bool = false

    /// 种子数据的逻辑版本号（你更新内置 JSON 时把它 +1）
    static let seedVersion: Int = 1

    private static let kLastSeedVersion = "SeedTemplates.lastSeedVersion"
    static var lastSeedVersion: Int {
        get { UserDefaults.standard.integer(forKey: kLastSeedVersion) }
        set { UserDefaults.standard.set(newValue, forKey: kLastSeedVersion) }
    }
}

// MARK: - 字符串归一化（仅用于去重比较，不改变存库内容）
private extension String {
    var normalizedEN: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .lowercased()
    }
    var normalizedZH: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

// MARK: - Use Case
@MainActor
struct SeedTemplatesUseCase {
    let context: ModelContext

    /// 若存在该目录则优先扫描；否则自动回退到扫描整个 bundle
    private let seedFolderName = "FoodSeeds"

    func run() async throws {
        print("🔧 Seed start → force=\(SeedConfig.forceReseed), seedVersion=\(SeedConfig.seedVersion), last=\(SeedConfig.lastSeedVersion)")

        // 1) 手动强制：每次做“增量导入”
        if SeedConfig.forceReseed {
            try await incrementalSeed()
            SeedConfig.lastSeedVersion = SeedConfig.seedVersion
            return
        }

        // 2) 已经导入过当前版本则直接返回
        if SeedConfig.lastSeedVersion >= SeedConfig.seedVersion {
            return
        }

        // 3) 判断库是否已有任何数据
        var d = FetchDescriptor<FoodTemplate>(); d.fetchLimit = 1
        let hasAny = (try? context.fetch(d))?.isEmpty == false

        if hasAny {
            // 已有数据：说明首导曾完成；本次仅更新标记，不做导入
            SeedConfig.lastSeedVersion = SeedConfig.seedVersion
            return
        } else {
            // 首次安装：完整导入一轮
            try await initialSeedOnce()
            SeedConfig.lastSeedVersion = SeedConfig.seedVersion
            return
        }
    }

    // MARK: - 首次导入（完整导入 + 种子内部去重）
    private func initialSeedOnce() async throws {
        let seeds = try loadAllSeedItems()

        // 对“新数据自身”按中/英文任一重复去重（英文大小写不敏感）
        var seenEN = Set<String>()
        var seenZH = Set<String>()
        var unique: [FoodTemplateRaw] = []

        for r in seeds {
            let en = r.nameEN.normalizedEN
            let zh = r.nameZH.normalizedZH
            if seenEN.contains(en) || seenZH.contains(zh) {
                print("⚠️ 跳过重复条目（种子内部）: \(r.nameZH) / \(r.nameEN)")
                continue
            }
            seenEN.insert(en); seenZH.insert(zh)
            unique.append(r)
        }

        for r in unique {
            context.insert(FoodTemplate(
                nameZH: r.nameZH,
                nameEN: r.nameEN,
                unit: r.unit,
                kcalPerUnit: r.kcalPerUnit,
                proteinPerUnit: r.proteinPerUnit,
                carbPerUnit: r.carbPerUnit,
                fatPerUnit: r.fatPerUnit
            ))
        }
        try context.save()
        print("✅ 初次导入 \(unique.count) 条预置食材（原始 \(seeds.count)）")
    }

    // MARK: - 增量导入（仅插入库中不存在的；既比库，也比本批）
    private func incrementalSeed() async throws {
        let seeds = try loadAllSeedItems()

        let existing = try fetchExistingNameSets()
        var inserted = 0
        var skipped = 0
        var batchEN = Set<String>()
        var batchZH = Set<String>()

        for r in seeds {
            let en = r.nameEN.normalizedEN
            let zh = r.nameZH.normalizedZH

            // 任一语言重复即跳过（和库、同批都比）
            if existing.en.contains(en) || existing.zh.contains(zh) || batchEN.contains(en) || batchZH.contains(zh) {
                skipped += 1
                print("⚠️ 跳过重复条目（库或批内）: \(r.nameZH) / \(r.nameEN)")
                continue
            }

            context.insert(FoodTemplate(
                nameZH: r.nameZH,
                nameEN: r.nameEN,
                unit: r.unit,
                kcalPerUnit: r.kcalPerUnit,
                proteinPerUnit: r.proteinPerUnit,
                carbPerUnit: r.carbPerUnit,
                fatPerUnit: r.fatPerUnit
            ))
            inserted += 1
            batchEN.insert(en); batchZH.insert(zh)
        }

        try context.save()
        print("✅ 增量导入完成：新增 \(inserted) 条，跳过 \(skipped) 条（总读取 \(seeds.count)）")
    }

    private func fetchExistingNameSets() throws -> (en: Set<String>, zh: Set<String>) {
        let all = try context.fetch(FetchDescriptor<FoodTemplate>())
        let en = Set(all.map { $0.nameEN.normalizedEN })
        let zh = Set(all.map { $0.nameZH.normalizedZH })
        return (en, zh)
    }

    // MARK: - Loader（自适应：优先 FoodSeeds 目录，找不到则回退扫描整个 bundle）
    private func loadAllSeedItems() throws -> [FoodTemplateRaw] {
        var candidateRoots: [URL] = []
        if let folder = Bundle.main.url(forResource: seedFolderName, withExtension: nil) {
            candidateRoots.append(folder)
        }
        if let bundleRoot = Bundle.main.resourceURL {
            candidateRoots.append(bundleRoot)
        }

        let fm = FileManager.default
        var all: [FoodTemplateRaw] = []
        var scannedFiles = 0
        var usedRoot: URL?

        outer: for root in candidateRoots {
            guard let en = fm.enumerator(at: root, includingPropertiesForKeys: nil) else { continue }
            var foundAnyJSON = false
            var tmp: [FoodTemplateRaw] = []

            for case let url as URL in en {
                if url.pathExtension.lowercased() == "json" {
                    foundAnyJSON = true
                    scannedFiles += 1
                    do {
                        let data = try Data(contentsOf: url)
                        let arr = try JSONDecoder().decode([FoodTemplateRaw].self, from: data)
                        tmp.append(contentsOf: arr)
                        print("📥 导入种子文件：\(url.lastPathComponent)，条目数=\(arr.count)")
                    } catch {
                        print("⚠️ 无法解析 \(url.lastPathComponent)：\(error)")
                    }
                }
            }

            if foundAnyJSON {
                all.append(contentsOf: tmp)
                usedRoot = root
                break outer
            }
        }

        if scannedFiles == 0 {
            print("⚠️ 未找到任何 .json 种子文件（已尝试目录：FoodSeeds 与 Bundle 根）")
            throw SeedError.missingFile
        }

        if let usedRoot {
            let tag = usedRoot.lastPathComponent == seedFolderName ? "FoodSeeds" : "BundleRoot"
            print("✅ 种子扫描完成（使用目录=\(tag)，文件数=\(scannedFiles)，汇总条目=\(all.count)）")
        }
        return all
    }

    enum SeedError: Error { case missingFile }
}

// MARK: - JSON 解码中转结构
private struct FoodTemplateRaw: Codable {
    let nameZH: String
    let nameEN: String
    let unit: UnitKind
    let kcalPerUnit: Double
    
    // 新增
    let proteinPerUnit: Double
    let carbPerUnit: Double
    let fatPerUnit: Double
}

