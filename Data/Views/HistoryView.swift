import SwiftUI
import Charts

struct HistoryView: View {
    @State private var records: [HistoryRecord] = []
    @State private var tz = TimeZone.current

    private let recentLimit = 10
    private let chartHeight: CGFloat = 160
    private let horizontalPadding: CGFloat = 16
    private let cardRadius: CGFloat = 16

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // 固定在顶部的「圆角卡片」容器，不随列表滚动
                chartCard
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 12)

                // Recent 列表只占用剩余空间，自己滚动；不影响上面的标题 & 图表
                recentList
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden) // 使用页面背景，而非列表默认背景
            }
            .navigationTitle(String(localized: "history"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            reload()
        }
    }

    private func reload() {
        let loader = HistoryLoader()
        self.records = loader.loadAllRecords(now: Date(), tz: tz)
    }

    private var recentBars: [HistoryRecord] {
        Array(records.suffix(recentLimit))
    }

    private var latestStart: Date? {
        recentBars.last?.start
    }

    // MARK: - Chart Card（圆角容器 + 图表，不横向滑动）
    private var chartCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            VStack(alignment: .leading, spacing: 8) {
                // 卡片标题（可选）
                Text(String(localized: "recent_summary"))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if recentBars.isEmpty {
                    VStack(spacing: 6) {
                        Text(String(localized: "no_history_yet"))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart {
                        ForEach(recentBars) { r in
                            let isLatest = (r.start == latestStart)
                            BarMark(
                                x: .value(String(localized: "start_unit"), r.start),
                                y: .value(String(localized: "kcal_unit"), r.totalKcal)
                            )
                            // 颜色：最新橙色，其余蓝色（你要求了指定颜色）
                            .foregroundStyle(isLatest ? .orange : .blue)
                        }
                    }
                    .chartLegend(.hidden)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: min(6, recentBars.count))) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let d = value.as(Date.self) {
                                    Text(shortDate(d))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: chartHeight)
                }
            }
            .padding(16)
        }
        .fixedSize(horizontal: false, vertical: true) // 避免被拉伸
    }

    // MARK: - Recent 列表（只在下半区域滚动）
    private var recentList: some View {
        List {
            Section(String(localized: "recent")) {
                if recentBars.isEmpty {
                    Text(String(localized: "no_history_yet"))
                        .foregroundStyle(Color.secondary)
                } else {
                    ForEach(recentBars.reversed()) { r in
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
                }
            }
        }
    }

    // MARK: - Formatting
    private func shortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "MM/dd"
        return f.string(from: d)
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
