import SwiftUI

// 可视化维度
enum HistoryMetric: String, CaseIterable, Identifiable {
    case kcal
    case protein
    case carb
    case fat

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .kcal:    return LocalizedStringKey("calories")   // 建议在本地化里配“热量”
        case .protein: return LocalizedStringKey("protein")    // “蛋白质”
        case .carb:    return LocalizedStringKey("carb")       // “碳水”
        case .fat:     return LocalizedStringKey("fat")        // “脂肪”
        }
    }
}

struct HistoryView: View {
    @State private var records: [HistoryRecord] = []
    @State private var tz = TimeZone.current
    @State private var selectedIndex: Int? = nil
    @State private var confirmDeleteAll = false

    // 新增：当前展示维度（默认热量）
    @State private var metric: HistoryMetric = .kcal

    private let recentLimit = 15

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                // ▶️ 顶部维度选择（分段控制）
                Picker("", selection: $metric) {
                    ForEach(HistoryMetric.allCases) { m in
                        Text(m.title).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                HistoryChartView(
                    records: recentBars,
                    selectedIndex: $selectedIndex,
                    tz: tz,
                    metric: metric              // ⬅️ 传入所选维度
                )
                .padding(Edge.Set.horizontal, 16)
                .padding(Edge.Set.top, 4)


                HistoryListView(
                    records: recentBars,
                    tz: tz,
                    onDelete: { record in
                        deleteRecord(record)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(String(localized: "history"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !records.isEmpty {
                        Button {
                            confirmDeleteAll = true
                        } label: {
                            Text(String(localized: "clear_history"))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .alert(
                Text(String(localized: "confirm_delete_all_title")),
                isPresented: $confirmDeleteAll
            ) {
                Button(role: .destructive) {
                    deleteAllRecent()
                } label: {
                    Text(String(localized: "clear_history"))
                }
                Button(role: .cancel) {
                    confirmDeleteAll = false
                } label: {
                    Text(String(localized: "cancel"))
                }
            } message: {
                Text(String(localized: "confirm_delete_all_message"))
            }
        }
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            reload()
        }
    }

    private func reload() {
        let loader = HistoryLoader()
        self.records = loader.loadAllRecords(now: Date())
    }

    private func deleteRecord(_ record: HistoryRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            withAnimation(.easeInOut) {
                _ = records.remove(at: index)
            }
        }
        let loader = HistoryLoader()
        loader.delete(record)
    }

    private func deleteAllRecent() {
        let loader = HistoryLoader()
        let toDelete = recentBars
        if toDelete.isEmpty { return }

        withAnimation(.easeInOut) {
            let ids = Set(toDelete.map { $0.id })
            records.removeAll { ids.contains($0.id) }
        }
        toDelete.forEach { loader.delete($0) }
    }

    private var recentBars: [HistoryRecord] {
        Array(records.suffix(recentLimit))
    }
}
