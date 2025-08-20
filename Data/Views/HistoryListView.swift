import SwiftUI

struct HistoryListView: View {
    let records: [HistoryRecord]
    let tz: TimeZone
    var onDelete: (HistoryRecord) -> Void

    var body: some View {
        List {
            Section(String(localized: "recent")) {
                if records.isEmpty {
                    Text(String(localized: "no_history_yet"))
                        .foregroundStyle(Color.secondary)
                } else {
                    let displayed = Array(records.reversed())

                    ForEach(displayed) { r in
                        row(r)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    onDelete(r)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    private func row(_ r: HistoryRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(startLabel(r.start))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(durationLabel(r.durationHours))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("kcal_with_unit \(Int64(r.totalKcal))")
                .font(.headline)
                .monospacedDigit()
        }
        .listRowSeparator(.visible)
    }

    private func startLabel(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: d)
    }

    private func durationLabel(_ hours: Double) -> LocalizedStringKey {
        let v = (hours.isFinite && hours >= 0) ? hours : 0
        return "duration_hours \(String(format: "%.1f", v))"
    }
}
