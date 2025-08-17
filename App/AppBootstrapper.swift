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
                // 转圈展位
                ProgressView()
            }
        }
        // 读取热量数据
        .task {
            do {
                try await SeedTemplatesUseCase(context: context).run()
            } catch {
                print("Seed failed: \(error)")
            }
            ready = true
        }
    }
}
