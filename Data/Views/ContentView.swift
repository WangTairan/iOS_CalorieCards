import SwiftUI

enum MainTab: Hashable {
    case today
    case history
}

struct ContentView: View {
    @State private var selected: MainTab = .today   // 默认 Today

    var body: some View {
        TabView(selection: $selected) {
            TodayView()
                .tabItem {
                    Label(String(localized: "today"), systemImage: "sun.max")
                }
                .tag(MainTab.today)

            HistoryView()
                .tabItem {
                    Label(String(localized: "history"), systemImage: "clock.arrow.circlepath")
                }
                .tag(MainTab.history)
        }
    }
}
