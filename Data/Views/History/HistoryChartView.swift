import SwiftUI
import Charts

struct HistoryChartView: View {
    let records: [HistoryRecord]
    @Binding var selectedIndex: Int?
    let tz: TimeZone

    private let chartHeight: CGFloat = 160
    private let cardRadius: CGFloat = 16

    private func slotX(forIndex i: Int) -> Double { Double(i + 1) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            VStack(alignment: .leading, spacing: 8) {
                if records.isEmpty {
                    VStack(spacing: 6) {
                        Text(String(localized: "no_history_yet"))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    let m = records.count
                    let lastIdx = m - 1
                    let lineData: [(x: Double, y: Double)] = records.enumerated().map { (i, r) in
                        (x: slotX(forIndex: i), y: Double(r.totalKcal))
                    }
                    let maxValue = Double(records.map { $0.totalKcal }.max() ?? 0)
                    let maxY = maxValue * 1.25
                    let bubbleOffset = maxValue * 0.05

                    Chart {
                        ForEach(Array(records.enumerated()), id: \.offset) { (i, r) in
                            let isToday = (i == lastIdx)
                            let isSelected = (selectedIndex == i)
                            let barBlue = Color.blue.opacity(0.20)
                            let barBlueSelected = Color.blue.opacity(0.60)
                            let barOrange = Color.orange.opacity(0.35)
                            let barOrangeSelected = Color.orange.opacity(0.90)
                            let dotStroke = Color.gray.opacity(0.85)

                            let color =
                                isToday ? (isSelected ? barOrangeSelected : barOrange)
                                        : (isSelected ? barBlueSelected   : barBlue)

                            BarMark(
                                x: .value("x", slotX(forIndex: i)),
                                y: .value("y", r.totalKcal),
                                width: .fixed(6) // 保持原始 barWidth
                            )
                            .foregroundStyle(color)

                            PointMark(
                                x: .value("x", slotX(forIndex: i)),
                                y: .value("y", r.totalKcal)
                            )
                            .symbol {
                                Circle()
                                    .strokeBorder(dotStroke, lineWidth: 2)
                                    .frame(width: 10, height: 10)
                            }

                            if isSelected {
                                PointMark(
                                    x: .value("x", slotX(forIndex: i)),
                                    y: .value("y", Double(r.totalKcal) + bubbleOffset)
                                )
                                .opacity(0)
                                .annotation(position: .top) {
                                    Text("kcal_with_unit \(Int64(r.totalKcal))")
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(Capsule())
                                }

                                PointMark(
                                    x: .value("x", slotX(forIndex: i)),
                                    y: .value("y", 0)
                                )
                                .opacity(0)
                                .annotation(position: .bottom) {
                                    Text(startLabel(r.start))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                }
                            }
                        }

                        ForEach(lineData, id: \.x) { p in
                            LineMark(
                                x: .value("x", p.x),
                                y: .value("y", p.y)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.cyan.opacity(0.90))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    .chartXScale(domain: 0...19)
                    .chartYScale(domain: 0...maxY)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 1)) { _ in
                            AxisTick()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartLegend(.hidden)
                    .chartPlotStyle { plot in
                        plot.padding(.horizontal, 4)
                    }
                    .frame(height: chartHeight)
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onEnded { value in
                                            let origin = geo[proxy.plotAreaFrame].origin
                                            let locX = value.location.x - origin.x
                                            if let chartX: Double = proxy.value(atX: locX) {
                                                let idx = Int(round(chartX - 1))
                                                if (0..<m).contains(idx) {
                                                    selectedIndex = idx
                                                } else {
                                                    selectedIndex = nil
                                                }
                                            } else {
                                                selectedIndex = nil
                                            }
                                        }
                                )
                                .onTapGesture {
                                    selectedIndex = nil
                                }
                        }
                    }
                }
            }
            .padding(16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func startLabel(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: d)
    }
}
