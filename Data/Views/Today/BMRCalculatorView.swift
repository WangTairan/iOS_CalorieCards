import SwiftUI

/// 活动系数
private enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary, light, moderate, active, veryActive

    var id: String { rawValue }

    var factor: Double {
        switch self {
        case .sedentary:   return 1.2
        case .light:       return 1.375
        case .moderate:    return 1.55
        case .active:      return 1.725
        case .veryActive:  return 1.9
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .sedentary:   return "sedentary"
        case .light:       return "light_activity"
        case .moderate:    return "moderate"
        case .active:      return "active"
        case .veryActive:  return "very_active"
        }
    }

    var hint: LocalizedStringKey {
        switch self {
        case .sedentary:   return "activity_hint_sedentary"
        case .light:       return "activity_hint_light"
        case .moderate:    return "activity_hint_moderate"
        case .active:      return "activity_hint_active"
        case .veryActive:  return "activity_hint_very_active"
        }
    }
}

struct BMRCalculatorView: View {
    // 持久化输入
    @AppStorage(AppKeys.lastSex)          private var lastSex: String = SexType.male.rawValue
    @AppStorage(AppKeys.lastAge)          private var lastAge: Int = 25
    @AppStorage(AppKeys.lastHeightCm)     private var lastHeightCm: Double = 175
    @AppStorage(AppKeys.lastWeightKg)     private var lastWeightKg: Double = 70
    @AppStorage(AppKeys.dailyKcalGoal)    private var dailyKcalGoal: Int = 2000
    @AppStorage(AppKeys.dailyProteinGoal) private var dailyProteinGoal: Int = 125
    @AppStorage(AppKeys.dailyCarbGoal)    private var dailyCarbGoal: Int = 250
    @AppStorage(AppKeys.dailyFatGoal)     private var dailyFatGoal: Int = 56
    @AppStorage("bmr.activityLevel")      private var storedActivity: String = ActivityLevel.moderate.rawValue

    // 页面状态
    @State private var sex: SexType = .male
    @State private var age: Double = 25
    @State private var heightCm: Double = 175
    @State private var weightKg: Double = 70
    @State private var activityLevel: ActivityLevel = .moderate

    // 公式：Mifflin–St Jeor
    private var bmr: Int {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * age
        let val = sex == .male ? base + 5 : base - 161
        return max(Int(val.rounded()), 0)
    }

    // 总量（BMR × 活动系数）
    private var totalKcal: Int {
        max(Int((Double(bmr) * activityLevel.factor).rounded()), 0)
    }

    // 根据比例计算宏目标（25/50/25）
    private var proteinGoal: Int {
        max(Int((Double(totalKcal) * 0.25 / 4).rounded()), 0)
    }
    private var carbGoal: Int {
        max(Int((Double(totalKcal) * 0.50 / 4).rounded()), 0)
    }
    private var fatGoal: Int {
        max(Int((Double(totalKcal) * 0.25 / 9).rounded()), 0)
    }

    var body: some View {
        Form {
            // ====== 基础代谢（BMR） ======
            Section {
                Picker(String(localized: "sex"), selection: $sex) {
                    ForEach(SexType.allCases) { s in
                        Text(s.localized).tag(s)
                    }
                }
                Stepper(value: $age, in: 10...100, step: 1) {
                    HStack {
                        Text(String(localized: "age"))
                        Spacer()
                        Text("\(Int(age))").monospacedDigit()
                    }
                }
                Stepper(value: $heightCm, in: 120...220, step: 1) {
                    HStack {
                        Text(String(localized: "height_cm"))
                        Spacer()
                        Text(String(localized: "cm_with_unit \(Int64(heightCm))"))
                            .monospacedDigit()
                    }
                }
                Stepper(value: $weightKg, in: 30...200, step: 0.5) {
                    HStack {
                        Text(String(localized: "weight_kg"))
                        Spacer()
                        Text("kg_with_unit \(weightKg)")
                            .monospacedDigit()
                    }
                }

                HStack {
                    Text(String(localized: "bmr_result")).font(.headline)
                    Spacer()
                    Text("kcal_with_unit \(Int64(bmr))")
                        .font(.headline)
                        .monospacedDigit()
                }
                Text(String(localized: "bmr_desc"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "bmr_section_title"))
            }

            // ====== 活动消耗 ======
            Section {
                Picker(String(localized: "activity_level"), selection: $activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        HStack {
                            Text(level.title)
                            Spacer()
                            Text(String(format: "× %.3g", level.factor))
                                .foregroundStyle(.secondary)
                        }
                        .tag(level)
                    }
                }

                Text(activityLevel.hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "exercise_section_title"))
            }

            // ====== 结果与应用 ======
            Section {
                HStack {
                    Text(String(localized: "total"))
                        .font(.headline)
                    Spacer()
                    Text("kcal_with_unit \(Int64(totalKcal))")
                        .font(.headline)
                        .monospacedDigit()
                }
                HStack {
                    Text(String(localized: "protein_goal"))
                    Spacer()
                    Text("g_with_unit \(Int64(proteinGoal))")
                        .monospacedDigit()
                }
                HStack {
                    Text(String(localized: "carb_goal"))
                    Spacer()
                    Text("g_with_unit \(Int64(proteinGoal))")
                        .monospacedDigit()
                }
                HStack {
                    Text(String(localized: "fat_goal"))
                    Spacer()
                    Text("g_with_unit \(Int64(fatGoal))")
                        .monospacedDigit()
                }

                Button {
                    dailyKcalGoal = totalKcal
                    dailyProteinGoal = proteinGoal
                    dailyCarbGoal = carbGoal
                    dailyFatGoal = fatGoal
                } label: {
                    HStack {
                        Image(systemName: "target")
                        Text(String(localized: "use_as_daily_goal"))
                        Spacer()
                        Text("kcal_with_unit \(Int64(dailyKcalGoal))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .navigationTitle(String(localized: "bmr_calculator"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 还原输入
            sex = SexType(rawValue: lastSex) ?? .male
            age = Double(lastAge)
            heightCm = lastHeightCm
            weightKg = lastWeightKg
            activityLevel = ActivityLevel(rawValue: storedActivity) ?? .moderate
        }
        .onDisappear {
            // 保存输入
            lastSex = sex.rawValue
            lastAge = Int(age.rounded())
            lastHeightCm = heightCm
            lastWeightKg = weightKg
            storedActivity = activityLevel.rawValue
        }
    }
}
