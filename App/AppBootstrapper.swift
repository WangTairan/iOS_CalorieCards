import SwiftUI
import SwiftData

/// 启动时做一次性初始化，然后切到主界面
struct AppBootstrapper: View {
    @Environment(\.modelContext) private var context
    @State private var ready = false

    var body: some View {
        Group {
            if ready {
                ContentView()
            } else {
                ProgressView() // 转圈占位
            }
        }
        .task {
            // 1. 初始化日切逻辑
            let mgr = DayCycleManager.shared
            mgr.tick()   // 👈 启动时立刻校正

            // 2. 种子数据
            do {
                try await SeedTemplatesUseCase(context: context).run()
            } catch {
                print("Seed failed: \(error)")
            }

            ready = true
        }
    }
}
