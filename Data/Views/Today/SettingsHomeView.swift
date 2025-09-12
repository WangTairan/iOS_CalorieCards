import SwiftUI

struct SettingsHomeView: View {
    @AppStorage(AppKeys.dailyKcalGoal) private var dailyKcalGoal: Int = 2000

    // 日切：本页直接弹出
    @State private var showingCutoffPicker = false
    @State private var pendingCutoffHour = DayCycleManager.shared.currentCutoff
    @State private var cutoffHour: Int = DayCycleManager.shared.currentCutoff

    // 目标设置：大 sheet
    @State private var showingGoalSheet = false

    var body: some View {
        List {
            // 日切时间（整行可点，右侧黑色文本）
            Button {
                pendingCutoffHour = cutoffHour
                showingCutoffPicker = true
            } label: {
                SettingsEntryRow(
                    title: String(localized: "day_end"),
                    systemImage: "clock.badge.checkmark"
                ) {
                    Text(String(format: "%02d:00", cutoffHour))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // 目标设置（右侧总是显示目标数值）→ 大 sheet
            Button {
                showingGoalSheet = true
            } label: {
                SettingsEntryRow(
                    title: String(localized: "goal_settings"),
                    systemImage: "target"
                ) {
                    Text("kcal_with_unit \(Int64(dailyKcalGoal))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // BMR 计算器（仍为页面）
            NavigationLink {
                BMRCalculatorView()
            } label: {
                SettingsEntryRow(
                    title: String(localized: "daily_nutrition_calculator"),
                    systemImage: "figure.strengthtraining.functional"
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listRowSeparator(.visible)
        .navigationTitle(String(localized: "settings"))
        .navigationBarTitleDisplayMode(.inline)

        // ===== 弹窗们 =====
        .sheet(isPresented: $showingCutoffPicker) {
            DayEndPicker(
                selectedHour: $pendingCutoffHour,
                onCancel: { showingCutoffPicker = false },
                onSave: {
                    DayCycleManager.shared.setCutoff(to: pendingCutoffHour)
                    cutoffHour = pendingCutoffHour      // 即时刷新
                    showingCutoffPicker = false
                }
            )
            .presentationDetents([.height(320), .medium])
        }
        .sheet(isPresented: $showingGoalSheet) {
            GoalSettingsView()
                .presentationDetents([.medium, .large]) // ✅ 大 sheet 手感（含中/大）
                .presentationCornerRadius(20)
        }

        .onAppear {
            cutoffHour = DayCycleManager.shared.currentCutoff
        }
    }
}
