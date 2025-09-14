import SwiftUI

private enum MacroCol {
    static let width: CGFloat = 64
}


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
                                    Label(String(localized: "delete"), systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    private func row(_ r: HistoryRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {

            // —— 第 1 行：时间（左） + 热量（右）
            HStack(alignment: .firstTextBaseline) {
                Text(startLabel(r.start))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)                       // 让左侧更不容易被挤没

                Spacer(minLength: 12)

                Text("kcal_with_unit \(Int64(r.totalKcal))")
                    .font(.headline)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)                // 数字过长时略缩放
            }

            // —— 第 2 行：持续时间（左，小字） + PCF（右，小字）
            HStack(alignment: .firstTextBaseline) {
                Text(durationLabel(r.durationHours))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    macroChip(labelKey: "macro_p", value: r.totalProtein)
                    macroChip(labelKey: "macro_c", value: r.totalCarb)
                    macroChip(labelKey: "macro_f", value: r.totalFat)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .listRowSeparator(.visible)
    }

    // 小块：固定列宽 + 右对齐 + 等宽数字
    private func macroChip(labelKey: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Text(LocalizedStringKey(labelKey))
            Text("g_with_unit \(Int64(value))").monospacedDigit() // "%lld g" / "%lld 克"
        }
        .frame(width: MacroCol.width, alignment: .trailing)
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
