import SwiftUI

enum MainTab: CaseIterable, Identifiable {
    case today, history, library
    var id: Self { self }

    var title: String {
        switch self {
        case .today: return String(localized: "today")
        case .history: return String(localized: "history")
        case .library: return String(localized: "library")
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max"
        case .history: return "clock.arrow.circlepath"
        case .library: return "books.vertical"
        }
    }
}

struct ContentView: View {
    @State private var selected: MainTab = .today
    @State private var todayHasOverlay = false

    // 🔑 每个 tab 单独维护一个 NavigationPath
    @State private var todayPath = NavigationPath()
    @State private var historyPath = NavigationPath()
    @State private var libraryPath = NavigationPath()

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom

            ZStack {
                VStack(spacing: 0) {
                    Group {
                        switch selected {
                        case .today:
                            NavigationStack(path: $todayPath) {
                                TodayView(hasOverlay: $todayHasOverlay)
                            }
                        case .history:
                            NavigationStack(path: $historyPath) {
                                HistoryView()
                            }
                        case .library:
                            NavigationStack(path: $libraryPath) {
                                LibraryView()
                            }
                        }
                    }

                    Divider()

                    CustomTabBar(selected: $selected)
                        .disabled(todayHasOverlay)
                }

                if selected == .today, todayHasOverlay {
                    VStack {
                        // ✅ 顶部禁用层（只用 safeTop，不再加 44）
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: safeTop + 44)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                NotificationCenter.default.post(name: .closeTodayOverlay, object: nil)
                            }

                        Spacer()

                        // ✅ 底部禁用层，保留 safeBottom + 系统 TabBar 高度
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: safeBottom + 49) // 49 是标准 TabBar 高度
                            .contentShape(Rectangle())
                            .onTapGesture {
                                NotificationCenter.default.post(name: .closeTodayOverlay, object: nil)
                            }
                    }
                    .ignoresSafeArea()
                    .zIndex(5)
                }
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: MainTab

    var body: some View {
        GeometryReader { proxy in
            let safeBottom = proxy.safeAreaInsets.bottom
            let barHeight: CGFloat = 49 // 系统 TabBar 标准高度

            HStack {
                ForEach(MainTab.allCases) { tab in
                    Button {
                        selected = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.title)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selected == tab ? .blue : .secondary)
                    }
                }
            }
            .frame(height: barHeight + safeBottom, alignment: .center)
            .padding(.bottom, safeBottom)
            .offset(y: -4) // 轻微上移，避免贴屏幕圆角
            .background(.ultraThinMaterial)
            .ignoresSafeArea(edges: .bottom)
        }
        .frame(height: 49) // 外层 frame 也改成 49
    }
}
