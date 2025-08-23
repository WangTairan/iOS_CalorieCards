import SwiftUI

struct HistoryView: View {
    @State private var records: [HistoryRecord] = []
    @State private var tz = TimeZone.current
    @State private var selectedIndex: Int? = nil
    @State private var confirmDeleteAll = false

    private let recentLimit = 15

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HistoryChartView(
                    records: recentBars,
                    selectedIndex: $selectedIndex,
                    tz: tz
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)

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
                                .foregroundStyle(.red)   // 纯文字红色
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
                records.remove(at: index)
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
