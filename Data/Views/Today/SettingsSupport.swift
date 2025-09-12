import SwiftUI

// MARK: - AppStorage Keys
enum AppKeys {
    static let dailyKcalGoal     = "dailyKcalGoal"
    static let dailyProteinGoal = "dailyProteinGoal"
    static let dailyCarbGoal    = "dailyCarbGoal"
    static let dailyFatGoal     = "dailyFatGoal"
    static let showGoalInToday   = "showGoalInToday"
    static let lastSex           = "bmr.lastSex"
    static let lastAge           = "bmr.lastAge"
    static let lastHeightCm      = "bmr.lastHeightCm"
    static let lastWeightKg      = "bmr.lastWeightKg"
}

// MARK: - SexType
enum SexType: String, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var localized: LocalizedStringKey {
        switch self {
        case .male: return LocalizedStringKey("male")
        case .female: return LocalizedStringKey("female")
        }
    }
}

// MARK: - 共用：设置行样式（仿 Library 样式）
struct SettingsEntryRow<Trailing: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var trailing: Trailing

    init(title: String, systemImage: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.systemImage = systemImage
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .padding(10)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))

            Text(title)
                .font(.headline)

            Spacer()
            trailing
        }
        .contentShape(Rectangle())
    }
}
